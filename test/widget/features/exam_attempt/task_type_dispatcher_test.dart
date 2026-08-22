import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_multiple_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_single_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/mc_multiple_option_list.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/mc_option_list.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

class _MockPendingMediaUploadDao extends Mock implements PendingMediaUploadDao {}

class _MockMediaUploadCoordinator extends Mock implements MediaUploadCoordinator {}

class _MockAudioPlayerService extends Mock implements AudioPlayerService {}

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

TaskView _mcMultipleTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_MULTIPLE',
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
  late _MockAudioRecorderService audioRecorderService;
  late _MockPendingMediaUploadDao mediaDao;
  late _MockMediaUploadCoordinator mediaUploadCoordinator;
  late _MockAudioPlayerService audioPlayerService;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    outboxDao = _MockAnswerOutboxDao();
    syncEngine = _MockSyncEngine();
    audioRecorderService = _MockAudioRecorderService();
    mediaDao = _MockPendingMediaUploadDao();
    mediaUploadCoordinator = _MockMediaUploadCoordinator();
    audioPlayerService = _MockAudioPlayerService();
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
          body: TaskTypeDispatcher(
            task: task,
            attemptPublicId: 'attempt-1',
            outboxDao: outboxDao,
            syncEngine: syncEngine,
            audioRecorderService: audioRecorderService,
            mediaDao: mediaDao,
            mediaUploadCoordinator: mediaUploadCoordinator,
            audioPlayerService: audioPlayerService,
          ),
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
      // Not READ_ALOUD — Phase 6 wired that taskType to a real screen, so
      // this needs a genuinely unsupported type to still exercise the
      // placeholder path.
      final task = TaskView(
        pinnedItemPublicId: 'item-3',
        orderIndex: 1,
        totalTasks: 5,
        section: 'SPEAKING',
        taskType: 'UNKNOWN_TASK_TYPE',
        title: 'Unsupported',
        prepSeconds: 30,
        responseSeconds: 60,
        prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
        responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
        serverNow: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildSubject(task));

      expect(find.text('Unsupported task type: UNKNOWN_TASK_TYPE'), findsOneWidget);
    });
  });

  group('TaskTypeDispatcher — MC_READING_MULTIPLE routing', () {
    testWidgets('routes to McMultipleOptionList / McReadingMultipleCubit, not the single-select path', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(_mcMultipleTask(pinnedItemPublicId: 'item-1')));

      expect(find.byType(McMultipleOptionList), findsOneWidget);
      expect(find.byType(McOptionList), findsNothing);
      final cubit = tester.element(find.byType(McMultipleOptionList)).read<McReadingMultipleCubit>();
      expect(cubit.pinnedItemPublicId, 'item-1');
    });

    testWidgets('ValueKey(pinnedItemPublicId) forces a fresh cubit for a new MC_READING_MULTIPLE task', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(_mcMultipleTask(pinnedItemPublicId: 'item-1')));
      final firstCubit = tester.element(find.byType(McMultipleOptionList)).read<McReadingMultipleCubit>();

      await tester.pumpWidget(buildSubject(_mcMultipleTask(pinnedItemPublicId: 'item-2')));
      final secondCubit = tester.element(find.byType(McMultipleOptionList)).read<McReadingMultipleCubit>();

      expect(identical(firstCubit, secondCubit), isFalse);
      expect(secondCubit.pinnedItemPublicId, 'item-2');
    });
  });
}
