import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/security/lockdown_mode.dart';
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

class _MockLockdownService extends Mock implements LockdownService {}

class _MockHeartbeatService extends Mock implements HeartbeatService {}

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

class _FakeTimerSnapshot extends Fake implements TimerSnapshot {}

class _StubAttemptTaskResponse {
  static AttemptTaskResponse make({String? lockdownMode, String attemptId = 'attempt-1'}) {
    return AttemptTaskResponse(
      attemptPublicId: attemptId,
      attemptStatus: 'IN_PROGRESS',
      completed: false,
      task: _task(),
      lockdownMode: lockdownMode,
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTimerSnapshot());
    registerFallbackValue(_task());
    registerFallbackValue(LockdownMode.none);
  });

  late _MockExamAttemptRepository repository;
  late _MockSessionEntryRepository sessionEntryRepository;
  late _MockSyncEngine syncEngine;
  late _MockTimerService timerService;
  late _MockMediaUploadCoordinator mediaUploadCoordinator;
  late _MockLockdownService lockdownService;
  late _MockHeartbeatService heartbeatService;

  setUp(() {
    repository = _MockExamAttemptRepository();
    sessionEntryRepository = _MockSessionEntryRepository();
    syncEngine = _MockSyncEngine();
    timerService = _MockTimerService();
    mediaUploadCoordinator = _MockMediaUploadCoordinator();
    lockdownService = _MockLockdownService();
    heartbeatService = _MockHeartbeatService();

    when(() => sessionEntryRepository.resolveSessionPublicId(any()))
        .thenAnswer((_) async => 'session-1');
    when(() => syncEngine.taskRejectedExternally)
        .thenAnswer((_) => const Stream<void>.empty());
    when(() => timerService.ticks)
        .thenAnswer((_) => const Stream<TimerSnapshot>.empty());
    when(() => timerService.taskAdvancedExternally)
        .thenAnswer((_) => const Stream<void>.empty());
    when(() => timerService.currentSnapshot).thenReturn(
      const TimerSnapshot(phase: TimerPhase.prep, remaining: Duration(seconds: 30), currentOrderIndex: 1),
    );
    when(() => syncEngine.startSync(any(), encryptionPublicKey: any(named: 'encryptionPublicKey')))
        .thenReturn(null);
    when(() => syncEngine.flushNow(any())).thenAnswer((_) async => 0);
    when(() => syncEngine.stopSync()).thenReturn(null);
    when(() => syncEngine.setActiveTask(any())).thenReturn(null);
    when(() => timerService.stop()).thenReturn(null);
    when(() => timerService.startPolling(any())).thenReturn(null);
    when(() => timerService.seedFromTask(any())).thenReturn(null);
    when(() => mediaUploadCoordinator.start()).thenReturn(null);
    when(() => mediaUploadCoordinator.stop()).thenReturn(null);
    when(() => heartbeatService.start(any())).thenReturn(null);
    when(() => heartbeatService.stop()).thenReturn(null);
    when(() => heartbeatService.dispose()).thenReturn(null);
    when(() => lockdownService.activateLockdown(
          mode: any(named: 'mode'),
          attemptPublicId: any(named: 'attemptPublicId'),
        )).thenAnswer((_) async {});
    when(() => lockdownService.deactivateLockdown()).thenAnswer((_) async {});
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
    'STRICT-mode attempt activates lockdown with the wire value parsed to LockdownMode.strict',
    setUp: () {
      when(() => repository.startOrResumeAttempt(any())).thenAnswer(
        (_) async => _StubAttemptTaskResponse.make(lockdownMode: 'STRICT'),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 's')),
    verify: (_) {
      verify(() => lockdownService.activateLockdown(
            mode: LockdownMode.strict,
            attemptPublicId: 'attempt-1',
          )).called(1);
      verify(() => syncEngine.startSync('attempt-1', encryptionPublicKey: any(named: 'encryptionPublicKey')))
          .called(1);
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'NONE-mode attempt skips lockdown activation entirely',
    setUp: () {
      when(() => repository.startOrResumeAttempt(any())).thenAnswer(
        (_) async => _StubAttemptTaskResponse.make(lockdownMode: 'NONE'),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 's')),
    verify: (_) {
      verifyNever(() => lockdownService.activateLockdown(
            mode: any(named: 'mode'),
            attemptPublicId: any(named: 'attemptPublicId'),
          ));
      verify(() => syncEngine.startSync('attempt-1', encryptionPublicKey: any(named: 'encryptionPublicKey')))
          .called(1);
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'null lockdownMode is treated as NONE — no lockdown activation, no error',
    setUp: () {
      when(() => repository.startOrResumeAttempt(any())).thenAnswer(
        (_) async => _StubAttemptTaskResponse.make(),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 's')),
    verify: (_) {
      verifyNever(() => lockdownService.activateLockdown(
            mode: any(named: 'mode'),
            attemptPublicId: any(named: 'attemptPublicId'),
          ));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'lockdown activation failure emits AttemptError with the same exception the bloc receives',
    setUp: () {
      when(() => repository.startOrResumeAttempt(any())).thenAnswer(
        (_) async => _StubAttemptTaskResponse.make(lockdownMode: 'STRICT'),
      );
      when(() => lockdownService.activateLockdown(
            mode: any(named: 'mode'),
            attemptPublicId: any(named: 'attemptPublicId'),
          )).thenThrow(const LockdownActivationException(
        'Hook failed',
        failedChecks: ['blockSystemShortcuts: hook failed'],
      ));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 's')),
    verify: (bloc) {
      expect(bloc.state, isA<AttemptError>());
      final error = (bloc.state as AttemptError).error;
      expect(error, isA<LockdownActivationException>());
      expect(
        (error as LockdownActivationException).failedChecks,
        ['blockSystemShortcuts: hook failed'],
      );
      verifyNever(() => syncEngine.startSync(any(), encryptionPublicKey: any(named: 'encryptionPublicKey')));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'deactivates lockdown as part of the terminal teardown',
    setUp: () {
      when(() => repository.startOrResumeAttempt(any())).thenAnswer(
        (_) async => _StubAttemptTaskResponse.make(lockdownMode: 'STRICT'),
      );
      when(() => repository.fetchNextTask('attempt-1')).thenAnswer(
        (_) async => AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'COMPLETED',
          completed: true,
        ),
      );
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 's'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested(reason: AdvanceReason.manual));
    },
    skip: 2,
    verify: (_) {
      verify(() => lockdownService.deactivateLockdown()).called(greaterThanOrEqualTo(1));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'close() also triggers a best-effort lockdown deactivation (so a hard quit never leaves hooks armed)',
    build: buildBloc,
    act: (bloc) async => bloc.close(),
    verify: (_) {
      // blocTest's own teardown calls bloc.close() again regardless of this
      // act already having closed it (mirrors the >=1 assertion above,
      // line 233, for the same double-invocation reason) — deactivateLockdown
      // is idempotent, so a second call is harmless.
      verify(() => lockdownService.deactivateLockdown()).called(greaterThanOrEqualTo(1));
    },
  );
}
