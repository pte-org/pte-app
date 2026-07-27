import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/mc_reading_single_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/mc_option_list.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockSyncEngine extends Mock implements SyncEngine {}

TaskView _mcTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    options: const [TaskOption(text: 'Option A', orderIndex: '1'), TaskOption(text: 'Option B', orderIndex: '2')],
    prepSeconds: 30,
    responseSeconds: 60,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
    responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
    serverNow: DateTime(2026, 1, 1),
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
    when(() => bloc.state).thenReturn(AttemptInProgress('attempt-1', _mcTask(pinnedItemPublicId: 'item-1'), snapshot));
    whenListen(bloc, const Stream<ExamAttemptState>.empty(), initialState: bloc.state);
  });

  Widget buildSubject(TaskView task) {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: Scaffold(
          body: TaskTypeDispatcher(task: task, attemptPublicId: 'attempt-1', outboxDao: outboxDao, syncEngine: syncEngine),
        ),
      ),
    );
  }

  group('TaskTypeDispatcher — ValueKey(pinnedItemPublicId) forces a fresh Element/cubit per task', () {
    testWidgets(
      'two consecutive MC_READING_SINGLE tasks with different pinnedItemPublicId produce distinct cubit instances',
      (tester) async {
        await tester.pumpWidget(buildSubject(_mcTask(pinnedItemPublicId: 'item-1')));
        final firstCubit = tester.element(find.byType(McOptionList)).read<McReadingSingleCubit>();
        expect(firstCubit.pinnedItemPublicId, 'item-1');

        await tester.pumpWidget(buildSubject(_mcTask(pinnedItemPublicId: 'item-2')));
        final secondCubit = tester.element(find.byType(McOptionList)).read<McReadingSingleCubit>();

        expect(
          identical(firstCubit, secondCubit),
          isFalse,
          reason: 'ValueKey(pinnedItemPublicId) must force Flutter to tear down and recreate the Element (and '
              'therefore the cubit) rather than reusing stale state across same-type consecutive tasks',
        );
        expect(secondCubit.pinnedItemPublicId, 'item-2');
      },
    );

    testWidgets('re-pumping with the same pinnedItemPublicId reuses the same cubit instance (sanity check)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(_mcTask(pinnedItemPublicId: 'item-1')));
      final firstCubit = tester.element(find.byType(McOptionList)).read<McReadingSingleCubit>();

      await tester.pumpWidget(buildSubject(_mcTask(pinnedItemPublicId: 'item-1')));
      final secondCubit = tester.element(find.byType(McOptionList)).read<McReadingSingleCubit>();

      expect(identical(firstCubit, secondCubit), isTrue);
    });

    testWidgets('an unsupported taskType renders the placeholder text, not a blank screen', (tester) async {
      final task = TaskView(
        pinnedItemPublicId: 'item-3',
        orderIndex: 1,
        totalTasks: 5,
        section: 'SPEAKING',
        taskType: 'READ_ALOUD',
        title: 'Unsupported',
        prepSeconds: 30,
        responseSeconds: 60,
        prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
        responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
        serverNow: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildSubject(task));

      expect(find.text('Unsupported task type: READ_ALOUD'), findsOneWidget);
    });
  });
}
