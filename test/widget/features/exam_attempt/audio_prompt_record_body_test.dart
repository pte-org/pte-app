import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart';

/// Isolated coverage for `AudioPromptRecordBody` itself — as opposed to
/// exercising it only indirectly through `RepeatSentenceScreen`/
/// `RetellLectureScreen`/`AnswerShortQuestionScreen`. Those 3 screens'
/// hardcoded `preListenSeconds`/`preRecordSeconds` values (3/3, 3/10, 3/3)
/// never sum to >= their `prepSeconds`, so the `_ListeningCard` "audio
/// window is non-positive" clamp (`audioSeconds <= 0 ? 1.0 : ...`) — real
/// widget logic introduced by moving these constants to per-call
/// constructor params — has zero coverage anywhere else in the suite. Only
/// this specific boundary is targeted here; every other code path in
/// `AudioPromptRecordBody` is already exercised at least 3x over by the
/// screens' own test suites.
class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockAutoRecordCubit extends MockCubit<AutoRecordState>
    implements AutoRecordCubit {}

void main() {
  late _MockExamAttemptBloc bloc;
  late _MockAutoRecordCubit autoRecordCubit;
  late StreamController<ExamAttemptState> stateController;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    autoRecordCubit = _MockAutoRecordCubit();
    stateController = StreamController<ExamAttemptState>.broadcast();
    when(() => autoRecordCubit.state).thenReturn(const AutoRecordState());
    whenListen(
      autoRecordCubit,
      const Stream<AutoRecordState>.empty(),
      initialState: const AutoRecordState(),
    );
  });

  tearDown(() => stateController.close());

  Widget buildSubject({
    required TaskView task,
    required int preListenSeconds,
    required int preRecordSeconds,
  }) {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: BlocProvider<AutoRecordCubit>.value(
          value: autoRecordCubit,
          child: Scaffold(
            body: AudioPromptRecordBody(
              task: task,
              preListenSeconds: preListenSeconds,
              preRecordSeconds: preRecordSeconds,
              instructionText: 'irrelevant instruction text',
            ),
          ),
        ),
      ),
    );
  }

  void stubBlocState(ExamAttemptState initial) {
    when(() => bloc.state).thenReturn(initial);
    whenListen(bloc, stateController.stream, initialState: initial);
  }

  testWidgets(
    'preListenSeconds + preRecordSeconds >= prepSeconds: the audio sub-stage is '
    'non-positive, so Listening clamps to "Playing 0 seconds left" at progress 1.0 '
    'instead of dividing by a zero/negative window — a boundary none of the 3 real '
    'screens\' fixed sub-stage constants ever reach',
    (tester) async {
      // prepSeconds=6, preListenSeconds=3, preRecordSeconds=5 (sum 8 > 6) ->
      // audioSeconds = (6 - 3 - 5).clamp(0, 6) = 0.
      final task = TaskView(
        pinnedItemPublicId: 'item-1',
        orderIndex: 1,
        totalTasks: 32,
        section: 'SPEAKING',
        taskType: 'ANSWER_SHORT_QUESTION',
        title: 'Boundary task',
        prepSeconds: 6,
        responseSeconds: 10,
        prepDeadline: DateTime(2026, 1, 1, 0, 0, 6),
        responseDeadline: DateTime(2026, 1, 1, 0, 0, 16),
        serverNow: DateTime(2026, 1, 1),
      );
      // elapsed = prepSeconds(6) - remaining(3) = 3, i.e. exactly at the
      // pre-listen -> audio sub-stage boundary.
      const snapshot = TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 3),
        currentOrderIndex: 1,
      );
      stubBlocState(AttemptInProgress('attempt-1', task, snapshot));

      await tester.pumpWidget(
        buildSubject(task: task, preListenSeconds: 3, preRecordSeconds: 5),
      );

      expect(find.text('Playing 0 seconds left'), findsOneWidget);
      // preRecordStart = (6 - 5).clamp(0, 6) = 1; elapsed(3) >= 1, so the
      // Record card is independently already in its own "Beginning in"
      // sub-stage (remaining = prepSeconds(6) - elapsed(3) = 3) —
      // unaffected by the Listening card's clamp.
      expect(find.text('Beginning in 3 seconds'), findsOneWidget);

      final progressBars = tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      // First bar belongs to the Listening card (declared before the
      // Record card in AudioPromptRecordBody's Column) and must be fully
      // filled (1.0) per the clamp, not NaN/negative from dividing by a
      // non-positive audioSeconds.
      expect(progressBars.first.value, 1.0);
    },
  );
}
