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
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/mc_reading_single_screen.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_task_header_banner.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockSyncEngine extends Mock implements SyncEngine {}

TaskView _mcTask({String? promptText}) {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    promptText: promptText,
    options: const [
      TaskOption(text: 'London', orderIndex: '0'),
      TaskOption(text: 'Paris', orderIndex: '1'),
    ],
    prepSeconds: 0,
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

    const snapshot = TimerSnapshot(phase: TimerPhase.response, remaining: Duration(seconds: 30), currentOrderIndex: 1);
    when(() => bloc.state).thenReturn(AttemptInProgress('attempt-1', _mcTask(), snapshot));
    whenListen(bloc, const Stream<ExamAttemptState>.empty(), initialState: bloc.state);
  });

  Widget buildSubject({String? promptText}) {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: McReadingSingleScreen(
          task: _mcTask(promptText: promptText),
          attemptPublicId: 'attempt-1',
          outboxDao: outboxDao,
          syncEngine: syncEngine,
        ),
      ),
    );
  }

  testWidgets('renders the banner with the MC_READING_SINGLE label', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.byType(ExamTaskHeaderBanner), findsOneWidget);
    expect(find.text('Reading: Multiple Choice, Single Answer'), findsOneWidget);
  });

  testWidgets('renders passage text when promptText is non-null', (tester) async {
    await tester.pumpWidget(buildSubject(promptText: 'A sample passage.'));

    expect(find.text('A sample passage.'), findsOneWidget);
  });

  testWidgets('renders no passage text (empty) when promptText is null, without throwing', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting an option writes its orderIndex via the outbox — existing behavior unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('Paris'));
    await tester.pump();

    verify(
      () => outboxDao.upsertAnswer(
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        payload: '1',
      ),
    ).called(1);
  });
}
