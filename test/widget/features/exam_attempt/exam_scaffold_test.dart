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
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

TaskView _task() {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task A',
    prepSeconds: 30,
    responseSeconds: 60,
  );
}

void main() {
  late _MockExamAttemptBloc bloc;
  late StreamController<ExamAttemptState> stateController;

  const snapshot = TimerSnapshot(phase: TimerPhase.response, remaining: Duration(seconds: 30), currentOrderIndex: 1);

  setUpAll(() {
    registerFallbackValue(const AppResumed());
  });

  setUp(() {
    bloc = _MockExamAttemptBloc();
    stateController = StreamController<ExamAttemptState>.broadcast();
    whenListen(bloc, stateController.stream, initialState: AttemptInProgress('attempt-1', _task(), snapshot));
  });

  tearDown(() async {
    await stateController.close();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: const ExamScaffold(totalTasks: 5, body: SizedBox.shrink()),
      ),
    );
  }

  testWidgets('the app returning to the foreground dispatches AppResumed', (tester) async {
    await tester.pumpWidget(buildSubject());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verify(() => bloc.add(any(that: isA<AppResumed>()))).called(1);
  });

  testWidgets('the app going to the background does not dispatch AppResumed', (tester) async {
    await tester.pumpWidget(buildSubject());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    verifyNever(() => bloc.add(any(that: isA<AppResumed>())));
  });

  testWidgets('the observer is removed on dispose — no AppResumed after the widget is gone', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verifyNever(() => bloc.add(any(that: isA<AppResumed>())));
  });
}
