import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_app_bar.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

TaskView _task({String title = 'Task A'}) {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: title,
    prepSeconds: 30,
    responseSeconds: 60,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
    responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
    serverNow: DateTime(2026, 1, 1),
  );
}

void main() {
  late _MockExamAttemptBloc bloc;
  late StreamController<ExamAttemptState> stateController;

  const snapshotA = TimerSnapshot(phase: TimerPhase.prep, remaining: Duration(seconds: 30), currentOrderIndex: 1);
  const snapshotB = TimerSnapshot(phase: TimerPhase.response, remaining: Duration(seconds: 12), currentOrderIndex: 1);

  setUp(() {
    bloc = _MockExamAttemptBloc();
    stateController = StreamController<ExamAttemptState>.broadcast();
    final initialState = AttemptInProgress('attempt-1', _task(), snapshotA);
    whenListen(bloc, stateController.stream, initialState: initialState);
  });

  tearDown(() async {
    await stateController.close();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: const Scaffold(body: ExamAppBar(totalTasks: 5)),
      ),
    );
  }

  /// The countdown `Text` is the third `Text` in `ExamAppBar`'s row (task
  /// counter, phase label, countdown) — its widget-object identity only
  /// changes when `BlocSelector`'s `builder` closure actually re-runs, i.e.
  /// only when the selected `TimerSnapshot` slice itself changed
  /// (`flutter_bloc`'s `_BlocBuilderBaseState.build` only calls `builder`
  /// again after a `setState` triggered by `buildWhen` returning true — see
  /// `BlocSelector`'s `listenWhen` gate). Comparing `identical()` across
  /// pumps is therefore a faithful proxy for "did the countdown widget
  /// rebuild", satisfying Step 12's "must be an executed test" requirement
  /// without needing to modify production code to inject a counter.
  Text countdownTextWidget(WidgetTester tester) => tester.widgetList<Text>(find.byType(Text)).elementAt(2);

  testWidgets(
    'an unrelated state change (task changes, TimerSnapshot slice unchanged) does not rebuild the countdown widget',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      final beforeText = countdownTextWidget(tester);
      expect((beforeText.data), '00:30');

      // Unrelated change: a different task, but the exact same
      // TimerSnapshot instance/value — mirrors what ExamAttemptBloc emits
      // when e.g. NextTaskRequested resolves but the timer hasn't ticked
      // yet in between.
      stateController.add(AttemptInProgress('attempt-1', _task(title: 'Task B'), snapshotA));
      await tester.pump();

      final afterUnrelatedText = countdownTextWidget(tester);
      expect(identical(beforeText, afterUnrelatedText), isTrue,
          reason: 'BlocSelector must not rebuild the countdown widget for a state change '
              'that leaves the TimerSnapshot slice unchanged');
      expect(afterUnrelatedText.data, '00:30');
    },
  );

  testWidgets('an actual TimerSnapshot change does rebuild the countdown widget', (tester) async {
    await tester.pumpWidget(buildSubject());
    final beforeText = countdownTextWidget(tester);

    stateController.add(AttemptInProgress('attempt-1', _task(), snapshotB));
    await tester.pump();

    final afterText = countdownTextWidget(tester);
    expect(identical(beforeText, afterText), isFalse,
        reason: 'BlocSelector must rebuild the countdown widget when the TimerSnapshot slice changes');
    expect(afterText.data, '00:12');
  });
}
