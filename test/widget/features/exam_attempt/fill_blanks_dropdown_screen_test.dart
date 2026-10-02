import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/widgets/status_banner.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/fill_blanks_dropdown_screen.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/fill_blanks_dropdown_body.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockSyncEngine extends Mock implements SyncEngine {}

TaskView _taskWithout(List<BlankGroup>? blankGroups) {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 0,
    totalTasks: 5,
    section: 'READING',
    taskType: 'FILL_IN_THE_BLANKS_DROPDOWN',
    title: 'title',
    promptText: 'It was {{0}}.',
    blankGroups: blankGroups,
    prepSeconds: 0,
    responseSeconds: 60,
  );
}

void main() {
  late _MockExamAttemptBloc bloc;
  late _MockAnswerOutboxDao outboxDao;
  late _MockSyncEngine syncEngine;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    outboxDao = _MockAnswerOutboxDao();
    syncEngine = _MockSyncEngine();
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(() => syncEngine.flushOne(any())).thenAnswer((_) async {});

    const snapshot = TimerSnapshot(phase: TimerPhase.response, remaining: Duration(seconds: 30), currentOrderIndex: 1);
    when(() => bloc.state).thenReturn(AttemptInProgress('attempt-1', _taskWithout(null), snapshot));
    whenListen(bloc, const Stream<ExamAttemptState>.empty(), initialState: bloc.state);
  });

  Widget buildSubject(TaskView task) {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: FillBlanksDropdownScreen(
          task: task,
          attemptPublicId: 'attempt-1',
          outboxDao: outboxDao,
          syncEngine: syncEngine,
        ),
      ),
    );
  }

  testWidgets('blankGroups == null renders StatusBanner fallback, not the interactive body or a crash', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(_taskWithout(null)));

    expect(find.byType(StatusBanner), findsOneWidget);
    expect(find.byType(FillBlanksDropdownBody), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blankGroups == [] (empty) also renders the fallback, not a blank interactive body', (tester) async {
    await tester.pumpWidget(buildSubject(_taskWithout(const [])));

    expect(find.byType(StatusBanner), findsOneWidget);
    expect(find.byType(FillBlanksDropdownBody), findsNothing);
  });

  testWidgets('the advance button is still present in the fallback state — the student is never stuck', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(_taskWithout(null)));

    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('blankGroups populated renders the interactive body, not the fallback', (tester) async {
    final task = _taskWithout(const [
      BlankGroup(blankIndex: 0, options: [TaskOption(text: 'sunny', orderIndex: '0')]),
    ]);
    await tester.pumpWidget(buildSubject(task));

    expect(find.byType(FillBlanksDropdownBody), findsOneWidget);
    expect(find.byType(StatusBanner), findsNothing);
  });
}
