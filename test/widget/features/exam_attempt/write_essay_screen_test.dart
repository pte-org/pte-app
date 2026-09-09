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
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/write_essay_screen.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockSyncEngine extends Mock implements SyncEngine {}

TaskView _essayTask() {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 1,
    totalTasks: 5,
    section: 'WRITING',
    taskType: 'WRITE_ESSAY',
    title: 'Task title',
    minWordCount: 40,
    maxWordCount: 100,
    prepSeconds: 30,
    responseSeconds: 300,
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
    when(() => bloc.state).thenReturn(AttemptInProgress('attempt-1', _essayTask(), snapshot));
    whenListen(bloc, const Stream<ExamAttemptState>.empty(), initialState: bloc.state);
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: WriteEssayScreen(
          task: _essayTask(),
          attemptPublicId: 'attempt-1',
          outboxDao: outboxDao,
          syncEngine: syncEngine,
        ),
      ),
    );
  }

  group('WriteEssayScreen — TextEditingController lifecycle (Step 10)', () {
    testWidgets('renders a TextField bound to a controller and disposes cleanly on teardown', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(TextField), findsOneWidget);

      // Tear the screen (and therefore its State, controller, and cubit)
      // out of the tree entirely.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('typing updates the word-count label live without throwing after teardown', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.pump();

      expect(find.textContaining('2 words'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('no FlutterError about a disposed-but-still-attached controller is thrown after replacing the tree', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextField), 'draft');
      await tester.pump();

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
