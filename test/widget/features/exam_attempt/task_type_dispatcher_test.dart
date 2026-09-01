import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
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

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

class _MockPendingMediaUploadDao extends Mock
    implements PendingMediaUploadDao {}

class _MockMediaUploadCoordinator extends Mock
    implements MediaUploadCoordinator {}

/// `RepeatSentenceScreen`/`ReadAloudScreen` construct their own cubit
/// internally using the real `resolveRecordingFilePath`, which calls
/// `path_provider` — no platform channel handler is registered in the
/// widget-test environment by default, so `getTemporaryDirectory()` throws
/// `MissingPluginException` unless this fake is installed.
class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => '/tmp';
}

TaskView _repeatSentenceTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'SPEAKING',
    taskType: 'REPEAT_SENTENCE',
    title: 'Task title',
    prepSeconds: 12,
    responseSeconds: 15,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 12),
    responseDeadline: DateTime(2026, 1, 1, 0, 0, 27),
    serverNow: DateTime(2026, 1, 1),
    // Server-owned as of plans/phat-speaking-dynamic-prep-timing — the
    // screen null-asserts these, so the fixture must always supply them.
    preListenSeconds: 3,
    preRecordSeconds: 3,
  );
}

TaskView _describeImageTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'SPEAKING',
    taskType: 'DESCRIBE_IMAGE',
    title: 'Task title',
    // imageUrl (server-resolved, plans/phat-describe-image-e2e) — not
    // imagePromptRef, which is only ever a raw MediaObject UUID.
    imageUrl: 'https://example.com/img.png',
    prepSeconds: 25,
    responseSeconds: 40,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 25),
    responseDeadline: DateTime(2026, 1, 1, 0, 1, 5),
    serverNow: DateTime(2026, 1, 1),
  );
}

TaskView _retellLectureTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'SPEAKING',
    taskType: 'RE_TELL_LECTURE',
    title: 'Task title',
    prepSeconds: 70,
    responseSeconds: 40,
    prepDeadline: DateTime(2026, 1, 1, 0, 1, 10),
    responseDeadline: DateTime(2026, 1, 1, 0, 1, 50),
    serverNow: DateTime(2026, 1, 1),
    // Server-owned as of plans/phat-speaking-dynamic-prep-timing — the
    // screen null-asserts these, so the fixture must always supply them.
    preListenSeconds: 3,
    preRecordSeconds: 10,
  );
}

TaskView _answerShortQuestionTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'SPEAKING',
    taskType: 'ANSWER_SHORT_QUESTION',
    title: 'Task title',
    prepSeconds: 14,
    responseSeconds: 10,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 14),
    responseDeadline: DateTime(2026, 1, 1, 0, 0, 24),
    serverNow: DateTime(2026, 1, 1),
    // Server-owned as of plans/phat-speaking-dynamic-prep-timing — the
    // screen null-asserts these, so the fixture must always supply them.
    preListenSeconds: 3,
    preRecordSeconds: 3,
  );
}

TaskView _summarizeGroupDiscussionTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'SPEAKING',
    taskType: 'SUMMARIZE_GROUP_DISCUSSION',
    title: 'Task title',
    prepSeconds: 200,
    responseSeconds: 120,
    prepDeadline: DateTime(2026, 1, 1, 0, 3, 20),
    responseDeadline: DateTime(2026, 1, 1, 0, 5, 20),
    serverNow: DateTime(2026, 1, 1),
    // Server-owned as of plans/phat-speaking-dynamic-prep-timing — the
    // screen null-asserts these, so the fixture must always supply them.
    preListenSeconds: 5,
    preRecordSeconds: 10,
  );
}

TaskView _respondToASituationTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'SPEAKING',
    taskType: 'RESPOND_TO_A_SITUATION',
    title: 'Task title',
    promptText: 'You are a student at a university.',
    prepSeconds: 40,
    responseSeconds: 40,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 40),
    responseDeadline: DateTime(2026, 1, 1, 0, 1, 20),
    serverNow: DateTime(2026, 1, 1),
    // Server-owned as of plans/phat-speaking-dynamic-prep-timing — the
    // screen null-asserts these, so the fixture must always supply them.
    preListenSeconds: 20,
    preRecordSeconds: 10,
  );
}

TaskView _personalIntroductionTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'SPEAKING',
    taskType: 'PERSONAL_INTRODUCTION',
    title: 'Task title',
    promptText: 'Please introduce yourself.',
    prepSeconds: 25,
    responseSeconds: 30,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 25),
    responseDeadline: DateTime(2026, 1, 1, 0, 0, 55),
    serverNow: DateTime(2026, 1, 1),
  );
}

class _MockAudioPlayerService extends Mock implements AudioPlayerService {}

class _MockAudioPromptRepository extends Mock
    implements AudioPromptRepository {}

TaskView _mcTask({required String pinnedItemPublicId}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    options: const [
      TaskOption(text: 'Option A', orderIndex: '1'),
      TaskOption(text: 'Option B', orderIndex: '2'),
    ],
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
    options: const [
      TaskOption(text: 'Option A', orderIndex: '1'),
      TaskOption(text: 'Option B', orderIndex: '2'),
    ],
    prepSeconds: 30,
    responseSeconds: 60,
    prepDeadline: DateTime(2026, 1, 1, 0, 0, 30),
    responseDeadline: DateTime(2026, 1, 1, 0, 1, 30),
    serverNow: DateTime(2026, 1, 1),
  );
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  late _MockExamAttemptBloc bloc;
  late _MockAnswerOutboxDao outboxDao;
  late _MockSyncEngine syncEngine;
  late _MockAudioRecorderService audioRecorderService;
  late _MockPendingMediaUploadDao mediaDao;
  late _MockMediaUploadCoordinator mediaUploadCoordinator;
  late _MockAudioPlayerService audioPlayerService;
  late _MockAudioPromptRepository audioPromptRepository;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    outboxDao = _MockAnswerOutboxDao();
    syncEngine = _MockSyncEngine();
    audioRecorderService = _MockAudioRecorderService();
    mediaDao = _MockPendingMediaUploadDao();
    mediaUploadCoordinator = _MockMediaUploadCoordinator();
    audioPlayerService = _MockAudioPlayerService();
    audioPromptRepository = _MockAudioPromptRepository();
    // AudioPromptCubit (constructed by every audio-prompt Speaking screen,
    // e.g. RepeatSentenceScreen) subscribes to these in its constructor
    // regardless of whether playback ever actually triggers.
    when(() => audioPlayerService.position).thenAnswer((_) => const Stream<Duration>.empty());
    when(() => audioPlayerService.duration).thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => audioPlayerService.playUrl(any())).thenAnswer((_) async {});
    when(() => audioPlayerService.close()).thenAnswer((_) async {});
    when(
      () => audioPromptRepository.playAudio(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        playRequestId: any(named: 'playRequestId'),
      ),
    ).thenAnswer((_) async => 'https://example.com/audio.mp3');
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(() => syncEngine.flushOne(any())).thenAnswer((_) async {});

    const snapshot = TimerSnapshot(
      phase: TimerPhase.response,
      remaining: Duration(seconds: 30),
      currentOrderIndex: 1,
    );
    when(() => bloc.state).thenReturn(
      AttemptInProgress(
        'attempt-1',
        _mcTask(pinnedItemPublicId: 'item-1'),
        snapshot,
      ),
    );
    whenListen(
      bloc,
      const Stream<ExamAttemptState>.empty(),
      initialState: bloc.state,
    );
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
            audioPromptRepository: audioPromptRepository,
          ),
        ),
      ),
    );
  }

  group(
    'TaskTypeDispatcher — ValueKey(pinnedItemPublicId) forces a fresh Element/cubit per task',
    () {
      testWidgets(
        'two consecutive MC_READING_SINGLE tasks with different pinnedItemPublicId produce distinct cubit instances',
        (tester) async {
          await tester.pumpWidget(
            buildSubject(_mcTask(pinnedItemPublicId: 'item-1')),
          );
          final firstCubit = tester
              .element(find.byType(McOptionList))
              .read<McReadingSingleCubit>();
          expect(firstCubit.pinnedItemPublicId, 'item-1');

          await tester.pumpWidget(
            buildSubject(_mcTask(pinnedItemPublicId: 'item-2')),
          );
          final secondCubit = tester
              .element(find.byType(McOptionList))
              .read<McReadingSingleCubit>();

          expect(
            identical(firstCubit, secondCubit),
            isFalse,
            reason:
                'ValueKey(pinnedItemPublicId) must force Flutter to tear down and recreate the Element (and '
                'therefore the cubit) rather than reusing stale state across same-type consecutive tasks',
          );
          expect(secondCubit.pinnedItemPublicId, 'item-2');
        },
      );

      testWidgets(
        're-pumping with the same pinnedItemPublicId reuses the same cubit instance (sanity check)',
        (tester) async {
          await tester.pumpWidget(
            buildSubject(_mcTask(pinnedItemPublicId: 'item-1')),
          );
          final firstCubit = tester
              .element(find.byType(McOptionList))
              .read<McReadingSingleCubit>();

          await tester.pumpWidget(
            buildSubject(_mcTask(pinnedItemPublicId: 'item-1')),
          );
          final secondCubit = tester
              .element(find.byType(McOptionList))
              .read<McReadingSingleCubit>();

          expect(identical(firstCubit, secondCubit), isTrue);
        },
      );

      testWidgets(
        'an unsupported taskType renders the placeholder text, not a blank screen',
        (tester) async {
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

          expect(
            find.text('Unsupported task type: UNKNOWN_TASK_TYPE'),
            findsOneWidget,
          );
        },
      );
    },
  );

  group('TaskTypeDispatcher — MC_READING_MULTIPLE routing', () {
    testWidgets(
      'routes to McMultipleOptionList / McReadingMultipleCubit, not the single-select path',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(_mcMultipleTask(pinnedItemPublicId: 'item-1')),
        );

        expect(find.byType(McMultipleOptionList), findsOneWidget);
        expect(find.byType(McOptionList), findsNothing);
        final cubit = tester
            .element(find.byType(McMultipleOptionList))
            .read<McReadingMultipleCubit>();
        expect(cubit.pinnedItemPublicId, 'item-1');
      },
    );

    testWidgets(
      'ValueKey(pinnedItemPublicId) forces a fresh cubit for a new MC_READING_MULTIPLE task',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(_mcMultipleTask(pinnedItemPublicId: 'item-1')),
        );
        final firstCubit = tester
            .element(find.byType(McMultipleOptionList))
            .read<McReadingMultipleCubit>();

        await tester.pumpWidget(
          buildSubject(_mcMultipleTask(pinnedItemPublicId: 'item-2')),
        );
        final secondCubit = tester
            .element(find.byType(McMultipleOptionList))
            .read<McReadingMultipleCubit>();

        expect(identical(firstCubit, secondCubit), isFalse);
        expect(secondCubit.pinnedItemPublicId, 'item-2');
      },
    );
  });

  group('TaskTypeDispatcher — REPEAT_SENTENCE routing', () {
    testWidgets(
      'routes to RepeatSentenceScreen, not the unsupported-task-type placeholder',
      (tester) async {
        // RepeatSentenceScreen constructs an AutoRecordCubit internally,
        // which subscribes to PendingMediaUploadDao.watchRow immediately in
        // its constructor — needs a stub even though this test never asserts
        // on upload status.
        when(
          () => mediaDao.watchRow(any(), any()),
        ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
        // A different pinnedItemPublicId than the default stubbed bloc
        // state's task ('item-1') so the timer-bridge identity guard never
        // matches — this test only checks routing/rendering, not auto-record
        // behavior, so no recorder stub is set up here.
        await tester.pumpWidget(
          buildSubject(_repeatSentenceTask(pinnedItemPublicId: 'item-99')),
        );

        expect(find.textContaining('Unsupported task type'), findsNothing);
        // The fixed instruction text is RepeatSentenceScreen-specific and
        // renders regardless of timer phase.
        expect(
          find.text(
            'You will hear a sentence. Please repeat the sentence exactly as you hear it. You will hear the '
            'sentence only once.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('TaskTypeDispatcher — DESCRIBE_IMAGE routing', () {
    testWidgets(
      'routes to DescribeImageScreen, not the unsupported-task-type placeholder',
      (tester) async {
        // DescribeImageScreen constructs an AutoRecordCubit internally, which
        // subscribes to PendingMediaUploadDao.watchRow immediately in its
        // constructor — needs a stub even though this test never asserts on
        // upload status.
        when(
          () => mediaDao.watchRow(any(), any()),
        ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
        // A different pinnedItemPublicId than the default stubbed bloc
        // state's task ('item-1') so the timer-bridge identity guard never
        // matches — this test only checks routing/rendering, not auto-record
        // behavior, so no recorder stub is set up here.
        await tester.pumpWidget(
          buildSubject(_describeImageTask(pinnedItemPublicId: 'item-99')),
        );

        expect(find.textContaining('Unsupported task type'), findsNothing);
        expect(
          find.text(
            'Look at the image below. In 25 seconds, please speak into the microphone and describe in detail '
            'what the image is showing. You will have 40 seconds to give your response.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('TaskTypeDispatcher — RE_TELL_LECTURE routing', () {
    testWidgets(
      'routes to RetellLectureScreen, not the unsupported-task-type placeholder',
      (tester) async {
        // RetellLectureScreen constructs an AutoRecordCubit internally, which
        // subscribes to PendingMediaUploadDao.watchRow immediately in its
        // constructor — needs a stub even though this test never asserts on
        // upload status.
        when(
          () => mediaDao.watchRow(any(), any()),
        ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
        // A different pinnedItemPublicId than the default stubbed bloc
        // state's task ('item-1') so the timer-bridge identity guard never
        // matches — this test only checks routing/rendering, not auto-record
        // behavior, so no recorder stub is set up here.
        await tester.pumpWidget(
          buildSubject(_retellLectureTask(pinnedItemPublicId: 'item-99')),
        );

        expect(find.textContaining('Unsupported task type'), findsNothing);
        expect(
          find.text(
            'You will hear a lecture. After listening to the lecture, in 10 seconds, please speak into the '
            'microphone and retell what you just heard from the lecture in your own words. You will have 40 '
            'seconds to give your response.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('TaskTypeDispatcher — ANSWER_SHORT_QUESTION routing', () {
    testWidgets(
      'routes to AnswerShortQuestionScreen, not the unsupported-task-type placeholder',
      (tester) async {
        // AnswerShortQuestionScreen constructs an AutoRecordCubit internally,
        // which subscribes to PendingMediaUploadDao.watchRow immediately in
        // its constructor — needs a stub even though this test never asserts
        // on upload status.
        when(
          () => mediaDao.watchRow(any(), any()),
        ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
        // A different pinnedItemPublicId than the default stubbed bloc
        // state's task ('item-1') so the timer-bridge identity guard never
        // matches — this test only checks routing/rendering, not auto-record
        // behavior, so no recorder stub is set up here.
        await tester.pumpWidget(
          buildSubject(_answerShortQuestionTask(pinnedItemPublicId: 'item-99')),
        );

        expect(find.textContaining('Unsupported task type'), findsNothing);
        expect(
          find.text(
            'You will hear a question. Please give a simple and short answer. Often just once or a few words '
            'is enough.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('TaskTypeDispatcher — PERSONAL_INTRODUCTION routing', () {
    testWidgets(
      'routes to PersonalIntroductionScreen, not the unsupported-task-type placeholder',
      (tester) async {
        // PersonalIntroductionScreen constructs an AutoRecordCubit internally,
        // which subscribes to PendingMediaUploadDao.watchRow immediately in
        // its constructor — needs a stub even though this test never asserts
        // on upload status.
        when(
          () => mediaDao.watchRow(any(), any()),
        ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
        // A different pinnedItemPublicId than the default stubbed bloc
        // state's task ('item-1') so the timer-bridge identity guard never
        // matches — this test only checks routing/rendering, not auto-record
        // behavior, so no recorder stub is set up here.
        await tester.pumpWidget(
          buildSubject(
            _personalIntroductionTask(pinnedItemPublicId: 'item-99'),
          ),
        );

        expect(find.textContaining('Unsupported task type'), findsNothing);
        expect(
          find.text(
            'Read the prompt below. In 25 seconds, you must reply in your own words, as naturally and clearly '
            'as possible. You have 30 seconds to record your response.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('TaskTypeDispatcher — SUMMARIZE_GROUP_DISCUSSION routing', () {
    testWidgets(
      'routes to SummarizeGroupDiscussionScreen, not the unsupported-task-type placeholder',
      (tester) async {
        // SummarizeGroupDiscussionScreen constructs an AutoRecordCubit
        // internally, which subscribes to PendingMediaUploadDao.watchRow
        // immediately in its constructor — needs a stub even though this
        // test never asserts on upload status.
        when(
          () => mediaDao.watchRow(any(), any()),
        ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
        // A different pinnedItemPublicId than the default stubbed bloc
        // state's task ('item-1') so the timer-bridge identity guard never
        // matches — this test only checks routing/rendering, not auto-record
        // behavior, so no recorder stub is set up here.
        await tester.pumpWidget(
          buildSubject(
            _summarizeGroupDiscussionTask(pinnedItemPublicId: 'item-99'),
          ),
        );

        expect(find.textContaining('Unsupported task type'), findsNothing);
        expect(
          find.text(
            'You will hear a group discussion. Please summarize the discussion, including the key points and '
            'opinions expressed by each speaker.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('TaskTypeDispatcher — RESPOND_TO_A_SITUATION routing', () {
    testWidgets(
      'routes to RespondToASituationScreen, not the unsupported-task-type placeholder',
      (tester) async {
        // RespondToASituationScreen constructs an AutoRecordCubit
        // internally, which subscribes to PendingMediaUploadDao.watchRow
        // immediately in its constructor — needs a stub even though this
        // test never asserts on upload status.
        when(
          () => mediaDao.watchRow(any(), any()),
        ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
        // A different pinnedItemPublicId than the default stubbed bloc
        // state's task ('item-1') so the timer-bridge identity guard never
        // matches — this test only checks routing/rendering, not auto-record
        // behavior, so no recorder stub is set up here.
        await tester.pumpWidget(
          buildSubject(_respondToASituationTask(pinnedItemPublicId: 'item-99')),
        );

        expect(find.textContaining('Unsupported task type'), findsNothing);
        expect(
          find.text(
            'Read the situation below. You will then hear it described again. Please respond appropriately, '
            'as you would in the actual situation.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
