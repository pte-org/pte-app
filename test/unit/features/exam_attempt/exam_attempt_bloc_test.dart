import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/platform/lockdown_exception.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/sync/submission_preparation_exception.dart';
import 'package:pte_app/features/exam_attempt/data/attempt_audio_cache.dart';
import 'package:pte_app/features/exam_attempt/domain/heartbeat_service.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_service.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';

class _MockExamAttemptRepository extends Mock
    implements ExamAttemptRepository {}

class _MockSessionEntryRepository extends Mock
    implements SessionEntryRepository {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockTimerService extends Mock implements TimerService {}

class _MockMediaUploadCoordinator extends Mock
    implements MediaUploadCoordinator {}

class _MockHeartbeatService extends Mock implements HeartbeatService {}

class _MockLockdownService extends Mock implements LockdownService {}

class _MockAttemptAudioCache extends Mock implements AttemptAudioCache {}

/// Stands in for "Member 3's eventual replacement" — a second, independent
/// `SessionEntryRepository` implementation used only to prove the
/// interface seam requires no `ExamAttemptBloc` change (phase-03 Steps 11).
class _AlternativeSessionEntryRepository implements SessionEntryRepository {
  _AlternativeSessionEntryRepository(this._sessionPublicId);

  final String _sessionPublicId;

  @override
  Future<String> resolveSessionPublicId(String rawInput) async =>
      _sessionPublicId;
}

// By default every fixture task is the last one according to the server, so a
// test only reloads the task list when it asks for a mid-exam task.
TaskView _task({
  String pinnedItemPublicId = 'item-1',
  int orderIndex = 4,
  int totalTasks = 5,
  String? audioUrl,
  String? imageUrl,
}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: orderIndex,
    totalTasks: totalTasks,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    prepSeconds: 30,
    responseSeconds: 60,
    audioUrl: audioUrl,
    imageUrl: imageUrl,
  );
}

AttemptTaskResponse _inProgressResponse({
  String attemptPublicId = 'attempt-1',
  String pinnedItemPublicId = 'item-1',
  int orderIndex = 4,
  String? audioUrl,
  String? imageUrl,
}) {
  return AttemptTaskResponse(
    attemptPublicId: attemptPublicId,
    attemptStatus: 'IN_PROGRESS',
    completed: false,
    task: _task(
      pinnedItemPublicId: pinnedItemPublicId,
      orderIndex: orderIndex,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
    ),
    lockdownMode: 'NONE',
  );
}

const _completedResponse = AttemptTaskResponse(
  attemptPublicId: 'attempt-1',
  attemptStatus: 'SUBMITTED',
  completed: true,
);

void main() {
  late _MockExamAttemptRepository repository;
  late _MockSessionEntryRepository sessionEntryRepository;
  late _MockSyncEngine syncEngine;
  late _MockTimerService timerService;
  late _MockMediaUploadCoordinator mediaUploadCoordinator;
  late _MockHeartbeatService heartbeatService;
  late _MockLockdownService lockdownService;

  setUpAll(() {
    // Required because `timerService.seedFromTask(any())` is stubbed below —
    // mocktail needs a fallback TaskView instance to satisfy `any()`
    // matching in null-safe mode.
    registerFallbackValue(_task());
  });

  setUp(() {
    repository = _MockExamAttemptRepository();
    sessionEntryRepository = _MockSessionEntryRepository();
    syncEngine = _MockSyncEngine();
    timerService = _MockTimerService();
    mediaUploadCoordinator = _MockMediaUploadCoordinator();
    heartbeatService = _MockHeartbeatService();
    lockdownService = _MockLockdownService();
    when(() => mediaUploadCoordinator.start()).thenReturn(null);
    when(() => mediaUploadCoordinator.stop()).thenReturn(null);
    when(() => heartbeatService.start(any())).thenReturn(null);
    when(() => heartbeatService.stop()).thenReturn(null);
    when(() => heartbeatService.dispose()).thenReturn(null);
    when(
      () => heartbeatService.sessionClosed,
    ).thenAnswer((_) => const Stream<void>.empty());
    when(() => lockdownService.deactivateLockdown()).thenAnswer((_) async {});
    when(
      () => lockdownService.activateAttemptExitGuard(
        attemptPublicId: any(named: 'attemptPublicId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => lockdownService.allowExitAfterSubmission(),
    ).thenAnswer((_) async {});
    when(
      () => lockdownService.deactivateAttemptExitGuard(),
    ).thenAnswer((_) async {});
    when(
      () => lockdownService.abortAttemptExitGuard(),
    ).thenAnswer((_) async {});
    when(
      () => mediaUploadCoordinator.flushBeforeSubmit(any()),
    ).thenAnswer((_) async {});
    when(() => syncEngine.flushBeforeSubmit(any())).thenAnswer((_) async {});
    when(() => syncEngine.setActiveTask(any())).thenReturn(null);
    when(() => syncEngine.startSync(any())).thenReturn(null);
    when(() => syncEngine.flushNow(any())).thenAnswer((_) async {});
    when(() => syncEngine.stopSync()).thenReturn(null);
    when(
      () => syncEngine.taskRejectedExternally,
    ).thenAnswer((_) => const Stream<String>.empty());
    when(
      () => timerService.ticks,
    ).thenAnswer((_) => const Stream<TimerSnapshot>.empty());
    when(
      () => timerService.taskAdvancedExternally,
    ).thenAnswer((_) => const Stream<void>.empty());
    when(() => timerService.seedFromTask(any())).thenReturn(null);
    when(() => timerService.startPolling(any())).thenReturn(null);
    when(() => timerService.stop()).thenReturn(null);
    when(() => timerService.currentSnapshot).thenReturn(
      const TimerSnapshot(
        phase: TimerPhase.prep,
        remaining: Duration(seconds: 30),
        currentOrderIndex: 1,
      ),
    );
    // Default stubs for the prefetch-all-tasks flow introduced in Phase 3.
    // Tests that need specific task lists override these in their own setUp.
    when(
      () => repository.fetchAllTasks(any()),
    ).thenAnswer((_) async => [_inProgressResponse()]);
    when(
      () => repository.forceSubmit(any()),
    ).thenAnswer((_) async => _completedResponse);
  });

  ExamAttemptBloc buildBloc() => ExamAttemptBloc(
    repository: repository,
    sessionEntryRepository: sessionEntryRepository,
    syncEngine: syncEngine,
    timerService: timerService,
    mediaUploadCoordinator: mediaUploadCoordinator,
    lockdownService: lockdownService,
    heartbeatService: heartbeatService,
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'completed:true, task:null produces AttemptCompleted, never AttemptError',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(
        () => repository.startOrResumeAttempt('session-1'),
      ).thenAnswer((_) async => _completedResponse);
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptCompleted>()],
    verify: (_) {
      verify(() => syncEngine.stopSync()).called(1);
      verifyNever(() => syncEngine.startSync(any()));
      verifyNever(() => syncEngine.flushNow(any()));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'completed:true without SUBMITTED acknowledgement fails closed',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => const AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'COMPLETED',
          completed: true,
        ),
      );
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptError>()],
    verify: (_) {
      verifyNever(() => lockdownService.allowExitAfterSubmission());
      verifyNever(() => syncEngine.startSync(any()));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'resuming an in-progress attempt calls SyncEngine.startSync then flushNow before AttemptInProgress is emitted '
    '(immediate flush of any leftover outbox rows, not a passive wait)',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(
        () => repository.startOrResumeAttempt('session-1'),
      ).thenAnswer((_) async => _inProgressResponse());
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
    verify: (_) {
      verifyInOrder([
        () => syncEngine.startSync('attempt-1'),
        () => syncEngine.flushNow('attempt-1'),
      ]);
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'start populates allTasks from fetchAllTasks so local navigation has the full list',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => _inProgressResponse(pinnedItemPublicId: 'item-1'),
      );
      when(() => repository.fetchAllTasks('attempt-1')).thenAnswer(
        (_) async => [
          _inProgressResponse(pinnedItemPublicId: 'item-1'),
          _inProgressResponse(pinnedItemPublicId: 'item-2'),
        ],
      );
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
    verify: (bloc) {
      final state = bloc.state as AttemptInProgress;
      expect(state.allTasks, hasLength(2));
      expect(state.currentIndex, 0);
      expect(state.task.pinnedItemPublicId, 'item-1');
      verify(() => repository.fetchAllTasks('attempt-1')).called(1);
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'NextTaskRequested advances currentIndex locally — no fetchNextTask call',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => _inProgressResponse(pinnedItemPublicId: 'item-1'),
      );
      when(() => repository.fetchAllTasks('attempt-1')).thenAnswer(
        (_) async => [
          _inProgressResponse(pinnedItemPublicId: 'item-1'),
          _inProgressResponse(pinnedItemPublicId: 'item-2'),
        ],
      );
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested());
    },
    expect: () => [
      isA<AttemptStarting>(),
      isA<AttemptInProgress>(),
      isA<AttemptInProgress>(),
    ],
    verify: (_) {
      verifyNever(() => repository.fetchNextTask(any()));
    },
  );

  group('NextTaskRequested forward-only guards', () {
    var clock = DateTime(2026, 11, 22, 10);

    ExamAttemptBloc buildClockedBloc() => ExamAttemptBloc(
      repository: repository,
      sessionEntryRepository: sessionEntryRepository,
      syncEngine: syncEngine,
      timerService: timerService,
      mediaUploadCoordinator: mediaUploadCoordinator,
      lockdownService: lockdownService,
      heartbeatService: heartbeatService,
      now: () => clock,
    );

    void arrangeThreeTasks() {
      clock = DateTime(2026, 11, 22, 10);
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => _inProgressResponse(pinnedItemPublicId: 'item-1'),
      );
      when(() => repository.fetchAllTasks('attempt-1')).thenAnswer(
        (_) async => [
          _inProgressResponse(pinnedItemPublicId: 'item-1'),
          _inProgressResponse(pinnedItemPublicId: 'item-2'),
          _inProgressResponse(pinnedItemPublicId: 'item-3'),
        ],
      );
    }

    Future<void> start(ExamAttemptBloc bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
      await Future<void>.delayed(Duration.zero);
    }

    int indexOf(ExamAttemptBloc bloc) =>
        (bloc.state as AttemptInProgress).currentIndex;

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'two requests for the same task move exactly one task',
      setUp: arrangeThreeTasks,
      build: buildClockedBloc,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const NextTaskRequested(fromPinnedItemPublicId: 'item-1'));
        bloc.add(const NextTaskRequested(fromPinnedItemPublicId: 'item-1'));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(indexOf(bloc), 1);
        verify(() => syncEngine.setActiveTask('item-2')).called(1);
        verifyNever(() => syncEngine.setActiveTask('item-3'));
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a tap right after a task became active is ignored; after the cooldown it moves on',
      setUp: arrangeThreeTasks,
      build: buildClockedBloc,
      act: (bloc) async {
        await start(bloc);
        bloc.add(
          const NextTaskRequested(
            fromPinnedItemPublicId: 'item-1',
            userInitiated: true,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        clock = clock.add(const Duration(milliseconds: 799));
        bloc.add(
          const NextTaskRequested(
            fromPinnedItemPublicId: 'item-2',
            userInitiated: true,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(indexOf(bloc), 1);
        clock = clock.add(const Duration(milliseconds: 2));
        bloc.add(
          const NextTaskRequested(
            fromPinnedItemPublicId: 'item-2',
            userInitiated: true,
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) => expect(indexOf(bloc), 2),
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'the first tap after start/resume has no cooldown',
      setUp: arrangeThreeTasks,
      build: buildClockedBloc,
      act: (bloc) async {
        await start(bloc);
        bloc.add(
          const NextTaskRequested(
            fromPinnedItemPublicId: 'item-1',
            userInitiated: true,
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) => expect(indexOf(bloc), 1),
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a timer/auto request for the active task is not blocked by the cooldown',
      setUp: arrangeThreeTasks,
      build: buildClockedBloc,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const NextTaskRequested(fromPinnedItemPublicId: 'item-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NextTaskRequested(
            reason: AdvanceReason.timeExpired,
            fromPinnedItemPublicId: 'item-2',
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) => expect(indexOf(bloc), 2),
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a rejection signal for a task that is no longer displayed does not skip another task',
      setUp: () {
        arrangeThreeTasks();
        final rejected = StreamController<String>.broadcast();
        addTearDown(rejected.close);
        when(
          () => syncEngine.taskRejectedExternally,
        ).thenAnswer((_) => rejected.stream);
        _rejectedControllerForTest = rejected;
      },
      build: buildClockedBloc,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const NextTaskRequested(fromPinnedItemPublicId: 'item-1'));
        await Future<void>.delayed(Duration.zero);
        _rejectedControllerForTest!.add('item-1');
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) => expect(indexOf(bloc), 1),
    );
  });

  group('Next when the prefetched task list is only the current task', () {
    void arrangeFallback({
      required Future<List<AttemptTaskResponse>> Function() reload,
    }) {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async =>
            _inProgressResponse(pinnedItemPublicId: 'item-1', orderIndex: 1),
      );
      var calls = 0;
      when(() => repository.fetchAllTasks('attempt-1')).thenAnswer((_) {
        // First call is the start prefetch, which fails and leaves one task.
        if (calls++ == 0) throw const NetworkException('offline');
        return reload();
      });
    }

    Future<void> startThenNext(ExamAttemptBloc bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested(fromPinnedItemPublicId: 'item-1'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'the server still has later tasks: reloads the list and moves to the next task',
      setUp: () => arrangeFallback(
        reload: () async => [
          _inProgressResponse(pinnedItemPublicId: 'item-1', orderIndex: 1),
          _inProgressResponse(pinnedItemPublicId: 'item-2', orderIndex: 2),
        ],
      ),
      build: buildBloc,
      act: startThenNext,
      verify: (bloc) {
        final state = bloc.state as AttemptInProgress;
        expect(state.task.pinnedItemPublicId, 'item-2');
        verifyNever(() => repository.forceSubmit(any()));
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'the reload also works when the server already marked the current task done',
      setUp: () => arrangeFallback(
        reload: () async => [
          _inProgressResponse(pinnedItemPublicId: 'item-2', orderIndex: 2),
        ],
      ),
      build: buildBloc,
      act: startThenNext,
      verify: (bloc) => expect(
        (bloc.state as AttemptInProgress).task.pinnedItemPublicId,
        'item-2',
      ),
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'the reload fails: stays on the task and does not submit the exam',
      setUp: () => arrangeFallback(
        reload: () async => throw const NetworkException('offline'),
      ),
      build: buildBloc,
      act: startThenNext,
      verify: (bloc) {
        expect(
          (bloc.state as AttemptInProgress).task.pinnedItemPublicId,
          'item-1',
        );
        verifyNever(() => repository.forceSubmit(any()));
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'the server agrees it is the last task: submits the exam as before',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => _inProgressResponse(pinnedItemPublicId: 'item-1'),
        );
      },
      build: buildBloc,
      act: startThenNext,
      verify: (_) {
        verify(() => repository.forceSubmit('attempt-1')).called(1);
      },
    );
  });

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'swapping SessionEntryRepository for a different implementation requires no change to ExamAttemptBloc',
    setUp: () {
      when(
        () => repository.startOrResumeAttempt('deep-link-session'),
      ).thenAnswer((_) async => _inProgressResponse());
    },
    build: () => ExamAttemptBloc(
      repository: repository,
      sessionEntryRepository: _AlternativeSessionEntryRepository(
        'deep-link-session',
      ),
      syncEngine: syncEngine,
      timerService: timerService,
      mediaUploadCoordinator: mediaUploadCoordinator,
      lockdownService: lockdownService,
      heartbeatService: heartbeatService,
    ),
    act: (bloc) =>
        bloc.add(const SessionResolutionRequested(rawInput: 'ignored-by-fake')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'AttemptCompleted calls stopSync exactly once; a stray NextTaskRequested afterward is a no-op, not a crash',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(
        () => repository.startOrResumeAttempt('session-1'),
      ).thenAnswer((_) async => _completedResponse);
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested());
    },
    expect: () => [isA<AttemptStarting>(), isA<AttemptCompleted>()],
    verify: (_) {
      verify(() => syncEngine.stopSync()).called(1);
      verifyNever(() => repository.fetchNextTask(any()));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'a SessionResolutionException results in AttemptError, never a crash or hang',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('')).thenThrow(
        const SessionResolutionException('Exam code cannot be empty.'),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: '')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptError>()],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'DEVICE_CHECK_REQUIRED exposes the session for the real pre-exam device-check screen',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(
        () => repository.startOrResumeAttempt('session-1'),
      ).thenThrow(const ConflictException('DEVICE_CHECK_REQUIRED'));
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [
      isA<AttemptStarting>(),
      isA<DeviceCheckRequired>().having(
        (state) => state.sessionPublicId,
        'sessionPublicId',
        'session-1',
      ),
    ],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'a confirmed device check retries the same session with deviceCheckConfirmed=true',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(
        () => repository.startOrResumeAttempt('session-1'),
      ).thenThrow(const ConflictException('DEVICE_CHECK_REQUIRED'));
      when(
        () => repository.startOrResumeAttempt(
          'session-1',
          deviceCheckConfirmed: true,
        ),
      ).thenAnswer((_) async => _inProgressResponse());
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const SessionResolutionRequested(
          rawInput: 'session-1',
          deviceCheckConfirmed: true,
        ),
      );
    },
    expect: () => [
      isA<AttemptStarting>(),
      isA<DeviceCheckRequired>(),
      isA<AttemptStarting>(),
      isA<AttemptInProgress>(),
    ],
    verify: (_) {
      verify(
        () => repository.startOrResumeAttempt(
          'session-1',
          deviceCheckConfirmed: true,
        ),
      ).called(1);
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'an unexpected non-ApiException failure (e.g. a malformed-response parse error) still reaches AttemptError, '
    'never left stranded in AttemptStarting',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(
        () => repository.startOrResumeAttempt('session-1'),
      ).thenThrow(const FormatException('bad json'));
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptError>()],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'completed:false with task:null (a contract violation) results in AttemptError without ever arming SyncEngine',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => const AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'IN_PROGRESS',
          completed: false,
        ),
      );
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptError>()],
    verify: (_) {
      verifyNever(() => syncEngine.startSync(any()));
      verifyNever(() => syncEngine.flushNow(any()));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'setActiveTask is called with the correct pinnedItemPublicId on every task transition, and null immediately before AttemptCompleted',
    setUp: () {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => _inProgressResponse(pinnedItemPublicId: 'item-1'),
      );
      when(() => repository.fetchAllTasks('attempt-1')).thenAnswer(
        (_) async => [
          _inProgressResponse(pinnedItemPublicId: 'item-1'),
          _inProgressResponse(pinnedItemPublicId: 'item-2'),
        ],
      );
      // forceSubmit fires when NextTaskRequested goes past the last item.
      when(
        () => repository.forceSubmit('attempt-1'),
      ).thenAnswer((_) async => _completedResponse);
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested());
    },
    expect: () => [
      isA<AttemptStarting>(),
      isA<AttemptInProgress>(),
      isA<AttemptInProgress>(),
      isA<AttemptInProgress>(),
      isA<AttemptCompleted>(),
    ],
    verify: (_) {
      verifyInOrder([
        () => syncEngine.setActiveTask('item-1'),
        () => syncEngine.setActiveTask('item-2'),
        () => syncEngine.setActiveTask(null),
      ]);
      verifyNever(() => repository.fetchNextTask(any()));
    },
  );

  group('AdvanceReason / AttemptCompleted.timeExpired (auto time\'s-up)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a normal NextTaskRequested() (default reason) that completes the attempt emits AttemptCompleted(timeExpired: false)',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        // Single-task allTasks: NextTaskRequested → ForceSubmitRequested.
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NextTaskRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptCompleted>(),
      ],
      verify: (bloc) {
        final completed = bloc.state as AttemptCompleted;
        expect(completed.timeExpired, isFalse);
        verifyNever(() => repository.fetchNextTask(any()));
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a NextTaskRequested(reason: timeExpired) that completes the attempt emits AttemptCompleted(timeExpired: true)',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        // Single-task allTasks: NextTaskRequested → ForceSubmitRequested.
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NextTaskRequested(reason: AdvanceReason.timeExpired));
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptCompleted>(),
      ],
      verify: (bloc) {
        final completed = bloc.state as AttemptCompleted;
        expect(completed.timeExpired, isTrue);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'ForceSubmitRequested always emits AttemptCompleted(timeExpired: false), even right after a timeExpired advance '
      'left the reason set (force-submit is always user-initiated)',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => _inProgressResponse(pinnedItemPublicId: 'item-1'),
        );
        when(() => repository.fetchAllTasks('attempt-1')).thenAnswer(
          (_) async => [
            _inProgressResponse(pinnedItemPublicId: 'item-1'),
            _inProgressResponse(pinnedItemPublicId: 'item-2'),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        // A timeExpired advance that does NOT itself complete the attempt
        // (there's a next task) — its reason must not leak into a later,
        // unrelated ForceSubmitRequested completion.
        bloc.add(const NextTaskRequested(reason: AdvanceReason.timeExpired));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptCompleted>(),
      ],
      verify: (bloc) {
        final completed = bloc.state as AttemptCompleted;
        expect(completed.timeExpired, isFalse);
      },
    );
  });

  group('ForceSubmitRequested (Step 10)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'dispatched from AttemptInProgress transitions to AttemptCompleted on a successful forceSubmit(), '
      'tearing down exactly like the natural end-of-tasks path',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptCompleted>(),
      ],
      verify: (_) {
        verifyInOrder([
          () => mediaUploadCoordinator.flushBeforeSubmit('attempt-1'),
          () => syncEngine.flushBeforeSubmit('attempt-1'),
          () => repository.forceSubmit('attempt-1'),
        ]);
        verify(() => syncEngine.stopSync()).called(1);
        verify(() => timerService.stop()).called(1);
        verify(() => mediaUploadCoordinator.stop()).called(1);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a forceSubmit() refused with SESSION_CLOSED ends the attempt instead of offering retry',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        when(
          () => repository.forceSubmit('attempt-1'),
        ).thenThrow(const ForbiddenException('SESSION_CLOSED'));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptSessionClosed>(),
      ],
      verify: (_) {
        verify(() => lockdownService.allowExitAfterSubmission()).called(1);
        verify(() => syncEngine.stopSync()).called(1);
        verify(() => timerService.stop()).called(1);
        verify(() => mediaUploadCoordinator.stop()).called(1);
      },
    );

    final sessionClosedSignal = StreamController<void>.broadcast();
    tearDownAll(sessionClosedSignal.close);
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'the heartbeat reporting SESSION_CLOSED ends the attempt and stops all syncing',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        when(
          () => heartbeatService.sessionClosed,
        ).thenAnswer((_) => sessionClosedSignal.stream);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        sessionClosedSignal.add(null);
      },
      wait: const Duration(milliseconds: 20),
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptSessionClosed>(),
      ],
      verify: (_) {
        verifyNever(() => repository.forceSubmit(any()));
        verify(() => syncEngine.stopSync()).called(1);
        verify(() => mediaUploadCoordinator.stop()).called(1);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a forceSubmit() failure stays on the attempt in a retryable state',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        when(
          () => repository.forceSubmit('attempt-1'),
        ).thenThrow(const NetworkException('connection refused'));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
      ],
      verify: (bloc) {
        final failed = bloc.state as AttemptInProgress;
        expect(
          failed.submissionStatus,
          AttemptSubmissionStatus.retryableFailure,
        );
        expect(failed.submissionError, isA<NetworkException>());
        // Failure must NOT run the teardown sequence — the attempt is
        // still considered running.
        verifyNever(() => syncEngine.stopSync());
        verifyNever(() => timerService.stop());
        verifyNever(() => mediaUploadCoordinator.stop());
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a native unlock failure stays guarded and exposes retry after server acknowledgement',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        when(
          () => lockdownService.allowExitAfterSubmission(),
        ).thenThrow(const ExitGuardException('native bridge unavailable'));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
      ],
      verify: (bloc) {
        final failed = bloc.state as AttemptInProgress;
        expect(
          failed.submissionStatus,
          AttemptSubmissionStatus.retryableFailure,
        );
        expect(failed.submissionError, isA<ExitGuardException>());
        verifyNever(() => syncEngine.stopSync());
        verifyNever(() => timerService.stop());
        verifyNever(() => mediaUploadCoordinator.stop());
        verify(() => lockdownService.allowExitAfterSubmission()).called(1);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'pending terminal preparation keeps the attempt guarded and never calls forceSubmit',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        when(
          () => mediaUploadCoordinator.flushBeforeSubmit('attempt-1'),
        ).thenThrow(
          const SubmissionPreparationException(
            kind: SubmissionPreparationKind.media,
            pendingCount: 1,
          ),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
      ],
      verify: (bloc) {
        final failed = bloc.state as AttemptInProgress;
        expect(
          failed.submissionStatus,
          AttemptSubmissionStatus.retryableFailure,
        );
        expect(failed.submissionError, isA<SubmissionPreparationException>());
        verifyNever(() => repository.forceSubmit(any()));
        verifyNever(() => syncEngine.stopSync());
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'ForceSubmitRequested with no attempt running (e.g. before any SessionResolutionRequested) is a no-op, not a crash',
      build: buildBloc,
      act: (bloc) => bloc.add(const ForceSubmitRequested()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => repository.forceSubmit(any()));
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a second ForceSubmitRequested arriving while the first is still in flight (e.g. the manual button\'s async '
      'confirm dialog racing the exam-clock-zero auto-trigger, bloc\'s default concurrent EventTransformer) is a '
      'no-op — never double-calls repository.forceSubmit and never overwrites AttemptCompleted with AttemptError '
      '(code review finding, client-side-exam-timer Phase 4)',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        when(() => repository.forceSubmit('attempt-1')).thenAnswer((_) async {
          // Never resolves within this test — the first call stays "in
          // flight" for the whole test, which is exactly the window the
          // second, racing event must be rejected in.
          await Completer<void>().future;
          return _completedResponse;
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
        await Future<void>.delayed(
          Duration.zero,
        ); // let the first handler start its await
        bloc.add(const ForceSubmitRequested());
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
      ],
      verify: (_) {
        verify(() => repository.forceSubmit('attempt-1')).called(1);
      },
    );
  });

  group('AppResumed (background/foreground resync)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'with an attempt running, re-fetches all tasks, re-seeds the timer and emits a refreshed AttemptInProgress',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        // fetchAllTasks is called twice: once on start, once on resume.
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AppResumed());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
      ],
      verify: (_) {
        verify(
          () => timerService.startPolling('attempt-1'),
        ).called(2); // once on start, once on resume
        verify(
          () => repository.fetchAllTasks('attempt-1'),
        ).called(2); // once on start, once on resume
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'with no attempt running (e.g. before any SessionResolutionRequested) is a no-op, not a crash',
      build: buildBloc,
      act: (bloc) => bloc.add(const AppResumed()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => timerService.startPolling(any()));
        verifyNever(() => repository.fetchAllTasks(any()));
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'AppResumed fetchAllTasks failure falls back to timer re-arm without emitting a new state',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        var callCount = 0;
        when(() => repository.fetchAllTasks('attempt-1')).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [_inProgressResponse()];
          throw const NetworkException('offline');
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AppResumed());
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
      verify: (_) {
        // Second startPolling call is the fallback timer re-arm.
        verify(() => timerService.startPolling('attempt-1')).called(2);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'AppResumed reconciles a server-submitted attempt before rearming the task shell',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
        var callCount = 0;
        when(() => repository.fetchAllTasks('attempt-1')).thenAnswer((_) async {
          callCount++;
          return callCount == 1
              ? [_inProgressResponse()]
              : [_completedResponse];
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AppResumed());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptCompleted>(),
      ],
      verify: (_) {
        verify(() => lockdownService.allowExitAfterSubmission()).called(1);
        verify(() => lockdownService.deactivateAttemptExitGuard()).called(1);
      },
    );
  });

  group('SyncTaskRejectedExternally regression (Step 8/9 wiring)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'when SyncEngine.taskRejectedExternally emits, the bloc advances locally — '
      'moving to the next item in allTasks without a fetchNextTask server call',
      setUp: () {
        final rejectedController = StreamController<String>.broadcast();
        addTearDown(rejectedController.close);
        when(
          () => syncEngine.taskRejectedExternally,
        ).thenAnswer((_) => rejectedController.stream);

        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => _inProgressResponse(pinnedItemPublicId: 'item-1'),
        );
        when(() => repository.fetchAllTasks('attempt-1')).thenAnswer(
          (_) async => [
            _inProgressResponse(pinnedItemPublicId: 'item-1'),
            _inProgressResponse(pinnedItemPublicId: 'item-2'),
          ],
        );

        _rejectedControllerForTest = rejectedController;
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        _rejectedControllerForTest!.add('item-1');
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
      ],
      verify: (_) {
        verifyNever(() => repository.fetchNextTask(any()));
        verify(() => syncEngine.setActiveTask('item-2')).called(1);
      },
    );
  });

  group('Offline listening audio cache', () {
    late _MockAttemptAudioCache audioCache;

    setUp(() {
      audioCache = _MockAttemptAudioCache();
      when(() => audioCache.prefetch(any())).thenAnswer((_) async {});
      when(() => audioCache.clear()).thenAnswer((_) async {});
    });

    ExamAttemptBloc buildCachedBloc() => ExamAttemptBloc(
      repository: repository,
      sessionEntryRepository: sessionEntryRepository,
      syncEngine: syncEngine,
      timerService: timerService,
      mediaUploadCoordinator: mediaUploadCoordinator,
      lockdownService: lockdownService,
      heartbeatService: heartbeatService,
      audioCache: audioCache,
    );

    void stubEntry(AttemptTaskResponse first, List<AttemptTaskResponse> all) {
      when(
        () => sessionEntryRepository.resolveSessionPublicId('session-1'),
      ).thenAnswer((_) async => 'session-1');
      when(
        () => repository.startOrResumeAttempt('session-1'),
      ).thenAnswer((_) async => first);
      when(
        () => repository.fetchAllTasks('attempt-1'),
      ).thenAnswer((_) async => all);
    }

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'prefetches the audio and images of every loaded task once the attempt is in progress',
      setUp: () => stubEntry(
        _inProgressResponse(audioUrl: 'https://cdn.test/1.mp3'),
        [
          _inProgressResponse(audioUrl: 'https://cdn.test/1.mp3'),
          _inProgressResponse(
            pinnedItemPublicId: 'item-2',
            imageUrl: 'https://cdn.test/2.png',
          ),
        ],
      ),
      build: buildCachedBloc,
      act: (bloc) =>
          bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
      verify: (_) {
        final urls =
            verify(() => audioCache.prefetch(captureAny())).captured.single
                as Iterable<String?>;
        expect(urls.whereType<String>().toList(), [
          'https://cdn.test/1.mp3',
          'https://cdn.test/2.png',
        ]);
        verifyNever(() => audioCache.clear());
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a failing prefetch never breaks the exam',
      setUp: () {
        stubEntry(_inProgressResponse(), [_inProgressResponse()]);
        when(
          () => audioCache.prefetch(any()),
        ).thenAnswer((_) async => throw StateError('disk full'));
      },
      build: buildCachedBloc,
      act: (bloc) =>
          bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'clears the cached audio when the attempt ends',
      setUp: () {
        stubEntry(_inProgressResponse(), [_inProgressResponse()]);
      },
      build: buildCachedBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
        isA<AttemptCompleted>(),
      ],
      verify: (_) {
        verify(() => audioCache.clear()).called(1);
      },
    );
  });

  group('Heartbeat wiring (client-side-exam-timer Phase 4)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'heartbeatService.start is called with the attempt id once the attempt becomes IN_PROGRESS',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
      verify: (_) {
        verify(() => heartbeatService.start('attempt-1')).called(1);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'is called again on every task transition — HeartbeatService\'s own idempotency (tested in '
      'heartbeat_service_test.dart) is what actually prevents the periodic cadence from restarting, not this bloc',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => _inProgressResponse(pinnedItemPublicId: 'item-1'),
        );
        when(() => repository.fetchAllTasks('attempt-1')).thenAnswer(
          (_) async => [
            _inProgressResponse(pinnedItemPublicId: 'item-1'),
            _inProgressResponse(pinnedItemPublicId: 'item-2'),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NextTaskRequested());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
      ],
      verify: (_) {
        verify(() => heartbeatService.start('attempt-1')).called(2);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'heartbeatService.stop is called when the attempt completes',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _completedResponse);
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
      expect: () => [isA<AttemptStarting>(), isA<AttemptCompleted>()],
      verify: (_) {
        verify(() => heartbeatService.stop()).called(1);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'AppResumed does not itself call heartbeatService.start — heartbeat is attempt-scoped, unlike '
      'TimerService.startPolling which AppResumed does re-arm',
      setUp: () {
        when(
          () => sessionEntryRepository.resolveSessionPublicId('session-1'),
        ).thenAnswer((_) async => 'session-1');
        when(
          () => repository.startOrResumeAttempt('session-1'),
        ).thenAnswer((_) async => _inProgressResponse());
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AppResumed());
      },
      expect: () => [
        isA<AttemptStarting>(),
        isA<AttemptInProgress>(),
        isA<AttemptInProgress>(),
      ],
      verify: (_) {
        verify(
          () => heartbeatService.start('attempt-1'),
        ).called(1); // only from the initial in-progress transition
      },
    );
  });

  group(
    'Exam-clock-zero auto force-submit (client-side-exam-timer Phase 4, FR-05)',
    () {
      blocTest<ExamAttemptBloc, ExamAttemptState>(
        'examRemaining reaching zero automatically triggers force-submit and completes the attempt — no server-side '
        'deadline check exists anymore to block it',
        setUp: () {
          when(
            () => sessionEntryRepository.resolveSessionPublicId('session-1'),
          ).thenAnswer((_) async => 'session-1');
          when(
            () => repository.startOrResumeAttempt('session-1'),
          ).thenAnswer((_) async => _inProgressResponse());
          when(() => timerService.currentSnapshot).thenReturn(
            const TimerSnapshot(
              phase: TimerPhase.prep,
              remaining: Duration(seconds: 30),
              currentOrderIndex: 1,
              examRemaining: Duration(minutes: 5),
            ),
          );
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
          await Future<void>.delayed(Duration.zero);
          bloc.add(
            const TimerSnapshotUpdated(
              TimerSnapshot(
                phase: TimerPhase.response,
                remaining: Duration.zero,
                currentOrderIndex: 1,
                examRemaining: Duration.zero,
              ),
            ),
          );
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<AttemptStarting>(),
          isA<AttemptInProgress>(),
          isA<AttemptInProgress>(),
          isA<AttemptInProgress>(),
          isA<AttemptCompleted>(),
        ],
        verify: (_) {
          verify(() => repository.forceSubmit('attempt-1')).called(1);
        },
      );

      blocTest<ExamAttemptBloc, ExamAttemptState>(
        'never auto-force-submits for an attempt whose examRemaining is always zero (no examEndTime known) — the '
        'transition check requires genuinely observing a prior > 0 value first',
        setUp: () {
          when(
            () => sessionEntryRepository.resolveSessionPublicId('session-1'),
          ).thenAnswer((_) async => 'session-1');
          when(
            () => repository.startOrResumeAttempt('session-1'),
          ).thenAnswer((_) async => _inProgressResponse());
          when(() => timerService.currentSnapshot).thenReturn(
            const TimerSnapshot(
              phase: TimerPhase.prep,
              remaining: Duration(seconds: 30),
              currentOrderIndex: 1,
            ),
          );
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
          await Future<void>.delayed(Duration.zero);
          bloc.add(
            const TimerSnapshotUpdated(
              TimerSnapshot(
                phase: TimerPhase.response,
                remaining: Duration.zero,
                currentOrderIndex: 1,
              ),
            ),
          );
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verifyNever(() => repository.forceSubmit(any()));
        },
      );
    },
  );
}

/// Holds the per-test StreamController so `act` can reach it after `setUp`
/// constructs it — `blocTest`'s `setUp`/`act` don't share a closure scope
/// otherwise.
StreamController<String>? _rejectedControllerForTest;
