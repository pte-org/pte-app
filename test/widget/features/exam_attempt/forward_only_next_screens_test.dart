import 'dart:async';

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
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/summarize_spoken_text_screen.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/mc_reading_single_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/write_essay_screen.dart';

// One representative screen per family whose Next lives in `TaskAdvanceButton`:
// Reading, Writing and Listening (Speaking is covered in read_aloud_screen_test).
// Each asserts forward-only: a Next button, never a Previous.

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockAudioPlayerService extends Mock implements AudioPlayerService {}

TaskView _task({
  required String section,
  required String taskType,
  String pinnedItemPublicId = 'item-1',
}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: section,
    taskType: taskType,
    title: 'Task title',
    minWordCount: 40,
    maxWordCount: 100,
    options: const [
      TaskOption(text: 'London', orderIndex: '0'),
      TaskOption(text: 'Paris', orderIndex: '1'),
    ],
    prepSeconds: 0,
    responseSeconds: 60,
  );
}

void main() {
  late _MockExamAttemptBloc bloc;
  late _MockAnswerOutboxDao outboxDao;
  late _MockSyncEngine syncEngine;
  late _MockAudioPlayerService player;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    outboxDao = _MockAnswerOutboxDao();
    syncEngine = _MockSyncEngine();
    player = _MockAudioPlayerService();
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(() => syncEngine.submitForAdvance(any())).thenAnswer((_) async {});
    when(() => player.play(any())).thenAnswer((_) async {});
    // Audio never finishes: Next must still be there while it plays.
    when(
      () => player.hasFinishedPlaying,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => player.position,
    ).thenAnswer((_) => const Stream<Duration>.empty());
    when(
      () => player.duration,
    ).thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => player.close()).thenAnswer((_) async {});
  });

  /// A two-task attempt positioned on [task], so it is not the last one.
  void seedAttempt(TaskView task) {
    const snapshot = TimerSnapshot(
      phase: TimerPhase.response,
      remaining: Duration(seconds: 30),
      currentOrderIndex: 1,
    );
    final initial = AttemptInProgress(
      'attempt-1',
      task,
      snapshot,
      allTasks: [task, task],
    );
    when(() => bloc.state).thenReturn(initial);
    whenListen(
      bloc,
      const Stream<ExamAttemptState>.empty(),
      initialState: initial,
    );
  }

  Widget host(Widget screen) => MaterialApp(
    home: BlocProvider<ExamAttemptBloc>.value(value: bloc, child: screen),
  );

  void expectForwardOnly(WidgetTester tester) {
    expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
    expect(find.textContaining('Previous'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  }

  testWidgets('Reading screen shows Next and no Previous', (tester) async {
    final task = _task(section: 'READING', taskType: 'MC_READING_SINGLE');
    seedAttempt(task);

    await tester.pumpWidget(
      host(
        McReadingSingleScreen(
          task: task,
          attemptPublicId: 'attempt-1',
          outboxDao: outboxDao,
          syncEngine: syncEngine,
        ),
      ),
    );

    expectForwardOnly(tester);
  });

  testWidgets('Writing screen shows Next and no Previous', (tester) async {
    final task = _task(section: 'WRITING', taskType: 'WRITE_ESSAY');
    seedAttempt(task);

    await tester.pumpWidget(
      host(
        WriteEssayScreen(
          task: task,
          attemptPublicId: 'attempt-1',
          outboxDao: outboxDao,
          syncEngine: syncEngine,
        ),
      ),
    );

    expectForwardOnly(tester);
  });

  testWidgets(
    'Summarize Spoken Text shows Next while its audio is still playing',
    (tester) async {
      final task = _task(
        section: 'LISTENING',
        taskType: 'SUMMARIZE_SPOKEN_TEXT',
      );
      seedAttempt(task);

      await tester.pumpWidget(
        host(
          SummarizeSpokenTextScreen(
            task: task,
            attemptPublicId: 'attempt-1',
            outboxDao: outboxDao,
            syncEngine: syncEngine,
            audioPlayerService: player,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Playing audio...'), findsOneWidget);
      expectForwardOnly(tester);
      final next = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(next.onPressed, isNotNull);
    },
  );
}
