import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
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

class _MockExamAttemptRepository extends Mock implements ExamAttemptRepository {}

class _MockSessionEntryRepository extends Mock implements SessionEntryRepository {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockTimerService extends Mock implements TimerService {}

class _MockMediaUploadCoordinator extends Mock implements MediaUploadCoordinator {}

class _MockHeartbeatService extends Mock implements HeartbeatService {}

class _MockLockdownService extends Mock implements LockdownService {}

/// Stands in for "Member 3's eventual replacement" — a second, independent
/// `SessionEntryRepository` implementation used only to prove the
/// interface seam requires no `ExamAttemptBloc` change (phase-03 Steps 11).
class _AlternativeSessionEntryRepository implements SessionEntryRepository {
  _AlternativeSessionEntryRepository(this._sessionPublicId);

  final String _sessionPublicId;

  @override
  Future<String> resolveSessionPublicId(String rawInput) async => _sessionPublicId;
}

TaskView _task({String pinnedItemPublicId = 'item-1'}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    prepSeconds: 30,
    responseSeconds: 60,
  );
}

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
    when(() => lockdownService.deactivateLockdown()).thenAnswer((_) async {});
    when(() => syncEngine.setActiveTask(any())).thenReturn(null);
    when(() => syncEngine.startSync(any())).thenReturn(null);
    when(() => syncEngine.flushNow(any())).thenAnswer((_) async {});
    when(() => syncEngine.stopSync()).thenReturn(null);
    when(() => syncEngine.taskRejectedExternally).thenAnswer((_) => const Stream<void>.empty());
    when(() => timerService.ticks).thenAnswer((_) => const Stream<TimerSnapshot>.empty());
    when(() => timerService.taskAdvancedExternally).thenAnswer((_) => const Stream<void>.empty());
    when(() => timerService.seedFromTask(any())).thenReturn(null);
    when(() => timerService.startPolling(any())).thenReturn(null);
    when(() => timerService.stop()).thenReturn(null);
    when(() => timerService.currentSnapshot).thenReturn(
      const TimerSnapshot(phase: TimerPhase.prep, remaining: Duration(seconds: 30), currentOrderIndex: 1),
    );
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
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async =>
            const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptCompleted>()],
    verify: (_) {
      verify(() => syncEngine.stopSync()).called(1);
      verifyNever(() => syncEngine.startSync(any()));
      verifyNever(() => syncEngine.flushNow(any()));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'resuming an in-progress attempt calls SyncEngine.startSync then flushNow before AttemptInProgress is emitted '
    '(immediate flush of any leftover outbox rows, not a passive wait)',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'IN_PROGRESS',
          completed: false,
          task: _task(),
        ),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
    verify: (_) {
      verifyInOrder([
        () => syncEngine.startSync('attempt-1'),
        () => syncEngine.flushNow('attempt-1'),
      ]);
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'swapping SessionEntryRepository for a different implementation requires no change to ExamAttemptBloc',
    setUp: () {
      when(() => repository.startOrResumeAttempt('deep-link-session')).thenAnswer(
        (_) async => AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'IN_PROGRESS',
          completed: false,
          task: _task(),
        ),
      );
    },
    build: () => ExamAttemptBloc(
      repository: repository,
      sessionEntryRepository: _AlternativeSessionEntryRepository('deep-link-session'),
      syncEngine: syncEngine,
      timerService: timerService,
      mediaUploadCoordinator: mediaUploadCoordinator,
      lockdownService: lockdownService,
      heartbeatService: heartbeatService,
    ),
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'ignored-by-fake')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'AttemptCompleted calls stopSync exactly once; a stray NextTaskRequested afterward is a no-op, not a crash',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async =>
            const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true),
      );
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
      when(() => sessionEntryRepository.resolveSessionPublicId(''))
          .thenThrow(const SessionResolutionException('Session ID cannot be empty.'));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: '')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptError>()],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'an unexpected non-ApiException failure (e.g. a malformed-response parse error) still reaches AttemptError, '
    'never left stranded in AttemptStarting',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenThrow(const FormatException('bad json'));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptError>()],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'completed:false with task:null (a contract violation) results in AttemptError without ever arming SyncEngine',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async =>
            const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'IN_PROGRESS', completed: false),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptError>()],
    verify: (_) {
      verifyNever(() => syncEngine.startSync(any()));
      verifyNever(() => syncEngine.flushNow(any()));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'setActiveTask is called with the correct pinnedItemPublicId on every task transition, and null immediately before AttemptCompleted',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'IN_PROGRESS',
          completed: false,
          task: _task(pinnedItemPublicId: 'item-1'),
        ),
      );

      var fetchCallCount = 0;
      when(() => repository.fetchNextTask('attempt-1')).thenAnswer((_) async {
        fetchCallCount++;
        if (fetchCallCount == 1) {
          return AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(pinnedItemPublicId: 'item-2'),
          );
        }
        return const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true);
      });
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
      isA<AttemptCompleted>(),
    ],
    verify: (_) {
      verifyInOrder([
        () => syncEngine.setActiveTask('item-1'),
        () => syncEngine.setActiveTask('item-2'),
        () => syncEngine.setActiveTask(null),
      ]);
    },
  );

  group('AdvanceReason / AttemptCompleted.timeExpired (auto time\'s-up)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a normal NextTaskRequested() (default reason) that completes the attempt emits AttemptCompleted(timeExpired: false)',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
        when(() => repository.fetchNextTask('attempt-1')).thenAnswer(
          (_) async => const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NextTaskRequested());
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>(), isA<AttemptCompleted>()],
      verify: (bloc) {
        final completed = bloc.state as AttemptCompleted;
        expect(completed.timeExpired, isFalse);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a NextTaskRequested(reason: timeExpired) that completes the attempt emits AttemptCompleted(timeExpired: true)',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
        when(() => repository.fetchNextTask('attempt-1')).thenAnswer(
          (_) async => const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NextTaskRequested(reason: AdvanceReason.timeExpired));
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>(), isA<AttemptCompleted>()],
      verify: (bloc) {
        final completed = bloc.state as AttemptCompleted;
        expect(completed.timeExpired, isTrue);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'ForceSubmitRequested always emits AttemptCompleted(timeExpired: false), even right after a timeExpired advance '
      'left the reason set (force-submit is always user-initiated)',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(pinnedItemPublicId: 'item-1'),
          ),
        );
        when(() => repository.fetchNextTask('attempt-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(pinnedItemPublicId: 'item-2'),
          ),
        );
        when(() => repository.forceSubmit('attempt-1')).thenAnswer((_) async {});
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
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
        when(() => repository.forceSubmit('attempt-1')).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>(), isA<AttemptCompleted>()],
      verify: (_) {
        verify(() => repository.forceSubmit('attempt-1')).called(1);
        verify(() => syncEngine.stopSync()).called(1);
        verify(() => timerService.stop()).called(1);
        verify(() => mediaUploadCoordinator.stop()).called(1);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'a forceSubmit() failure emits AttemptError, not a crash or hang',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
        when(() => repository.forceSubmit('attempt-1')).thenThrow(const NetworkException('connection refused'));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>(), isA<AttemptError>()],
      verify: (_) {
        // Failure must NOT run the teardown sequence — the attempt is
        // still considered running.
        verifyNever(() => syncEngine.stopSync());
        verifyNever(() => timerService.stop());
        verifyNever(() => mediaUploadCoordinator.stop());
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
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
        final forceSubmitStarted = Completer<void>();
        when(() => repository.forceSubmit('attempt-1')).thenAnswer((_) async {
          forceSubmitStarted.complete();
          // Never resolves within this test — the first call stays "in
          // flight" for the whole test, which is exactly the window the
          // second, racing event must be rejected in.
          return Completer<void>().future;
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ForceSubmitRequested());
        await Future<void>.delayed(Duration.zero); // let the first handler start its await
        bloc.add(const ForceSubmitRequested());
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
      verify: (_) {
        verify(() => repository.forceSubmit('attempt-1')).called(1);
      },
    );
  });

  group('AppResumed (background/foreground resync)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'with an attempt running, re-arms TimerService.startPolling for the current attempt without emitting a new state',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AppResumed());
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
      verify: (_) {
        verify(() => timerService.startPolling('attempt-1')).called(2); // once on start, once on resume
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'with no attempt running (e.g. before any SessionResolutionRequested) is a no-op, not a crash',
      build: buildBloc,
      act: (bloc) => bloc.add(const AppResumed()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => timerService.startPolling(any()));
      },
    );
  });

  group('SyncTaskRejectedExternally regression (Step 8/9 wiring)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'when SyncEngine.taskRejectedExternally emits, the bloc re-fetches next-task the same way '
      'TimerTaskAdvancedExternally does — advancing past the server-rejected stale task',
      setUp: () {
        final rejectedController = StreamController<void>.broadcast();
        addTearDown(rejectedController.close);
        // Overrides the blanket Stream.empty() stub from the outer setUp so
        // this test can emit on it directly.
        when(() => syncEngine.taskRejectedExternally).thenAnswer((_) => rejectedController.stream);

        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(pinnedItemPublicId: 'item-1'),
          ),
        );
        when(() => repository.fetchNextTask('attempt-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(pinnedItemPublicId: 'item-2'),
          ),
        );

        _rejectedControllerForTest = rejectedController;
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        _rejectedControllerForTest!.add(null);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>(), isA<AttemptInProgress>()],
      verify: (_) {
        verify(() => repository.fetchNextTask('attempt-1')).called(1);
        verify(() => syncEngine.setActiveTask('item-2')).called(1);
      },
    );
  });

  group('Heartbeat wiring (client-side-exam-timer Phase 4)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'heartbeatService.start is called with the attempt id once the attempt becomes IN_PROGRESS',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
      verify: (_) {
        verify(() => heartbeatService.start('attempt-1')).called(1);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'is called again on every task transition — HeartbeatService\'s own idempotency (tested in '
      'heartbeat_service_test.dart) is what actually prevents the periodic cadence from restarting, not this bloc',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(pinnedItemPublicId: 'item-1'),
          ),
        );
        when(() => repository.fetchNextTask('attempt-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(pinnedItemPublicId: 'item-2'),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NextTaskRequested());
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>(), isA<AttemptInProgress>()],
      verify: (_) {
        verify(() => heartbeatService.start('attempt-1')).called(2);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'heartbeatService.stop is called when the attempt completes',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async =>
              const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
      expect: () => [isA<AttemptStarting>(), isA<AttemptCompleted>()],
      verify: (_) {
        verify(() => heartbeatService.stop()).called(1);
      },
    );

    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'AppResumed does not itself call heartbeatService.start — heartbeat is attempt-scoped, unlike '
      'TimerService.startPolling which AppResumed does re-arm',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AppResumed());
      },
      expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
      verify: (_) {
        verify(() => heartbeatService.start('attempt-1')).called(1); // only from the initial in-progress transition
      },
    );
  });

  group('Exam-clock-zero auto force-submit (client-side-exam-timer Phase 4, FR-05)', () {
    blocTest<ExamAttemptBloc, ExamAttemptState>(
      'examRemaining reaching zero automatically triggers force-submit and completes the attempt — no server-side '
      'deadline check exists anymore to block it',
      setUp: () {
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
        when(() => timerService.currentSnapshot).thenReturn(
          const TimerSnapshot(
            phase: TimerPhase.prep,
            remaining: Duration(seconds: 30),
            currentOrderIndex: 1,
            examRemaining: Duration(minutes: 5),
          ),
        );
        when(() => repository.forceSubmit('attempt-1')).thenAnswer((_) async {});
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
        when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
        when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
          (_) async => AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(),
          ),
        );
        when(() => timerService.currentSnapshot).thenReturn(
          const TimerSnapshot(phase: TimerPhase.prep, remaining: Duration(seconds: 30), currentOrderIndex: 1),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const TimerSnapshotUpdated(
            TimerSnapshot(phase: TimerPhase.response, remaining: Duration.zero, currentOrderIndex: 1),
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verifyNever(() => repository.forceSubmit(any()));
      },
    );
  });
}

/// Holds the per-test StreamController so `act` can reach it after `setUp`
/// constructs it — `blocTest`'s `setUp`/`act` don't share a closure scope
/// otherwise.
StreamController<void>? _rejectedControllerForTest;
