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
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_playback_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart';

/// Isolated coverage for `AudioPromptRecordBody` itself — as opposed to
/// exercising it only indirectly through `RepeatSentenceScreen`/
/// `RetellLectureScreen`/`AnswerShortQuestionScreen`. The "Playing" label's
/// countdown text stays timer-driven (still real widget arithmetic tested
/// here — the non-positive-audio-window boundary none of the 3 real
/// screens' fixed sub-stage constants ever reach); the progress *bar*
/// itself is driven by `AudioPromptCubit`'s state instead
/// (plans/phat-speaking-audio-prompt-e2e), so this test now proves that
/// wiring — the bar reflects the cubit's `progress` verbatim — rather than
/// re-deriving it from `audioSeconds`.
class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockAutoRecordCubit extends MockCubit<AutoRecordState>
    implements AutoRecordCubit {}

class _MockAudioPromptCubit extends MockCubit<AudioPromptPlaybackState>
    implements AudioPromptCubit {}

void main() {
  late _MockExamAttemptBloc bloc;
  late _MockAutoRecordCubit autoRecordCubit;
  late _MockAudioPromptCubit audioPromptCubit;
  late StreamController<ExamAttemptState> stateController;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    autoRecordCubit = _MockAutoRecordCubit();
    audioPromptCubit = _MockAudioPromptCubit();
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
          child: BlocProvider<AudioPromptCubit>.value(
            value: audioPromptCubit,
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
      when(() => audioPromptCubit.state).thenReturn(const AudioPromptPlaybackState(
        phase: AudioPromptPlaybackPhase.playing,
        progress: 0.73,
      ));
      whenListen(
        audioPromptCubit,
        const Stream<AudioPromptPlaybackState>.empty(),
        initialState: const AudioPromptPlaybackState(
          phase: AudioPromptPlaybackPhase.playing,
          progress: 0.73,
        ),
      );

      await tester.pumpWidget(
        buildSubject(task: task, preListenSeconds: 3, preRecordSeconds: 5),
      );

      // The countdown label text stays real timer-driven arithmetic —
      // "Playing 0 seconds left" here is the still-relevant non-positive-
      // audio-window clamp (audioSeconds = (6 - 3 - 5).clamp(0, 6) = 0).
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
      // Record card in AudioPromptRecordBody's Column) — its fill now
      // comes verbatim from AudioPromptCubit's state, not from re-deriving
      // audioSeconds locally, so it must match the stubbed 0.73 exactly.
      expect(progressBars.first.value, 0.73);
    },
  );
}
