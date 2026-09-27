import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/security/lockdown_mode.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/heartbeat_service.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_navigation_direction.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_service.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';

/// No `BuildContext` here — navigation/side effects are driven by the UI
/// listening to this bloc's state changes, matching Phase 1's `AuthBloc`
/// constraint.
///
/// Depends on `SyncEngine` only, never `AnswerOutboxDao` directly — resume
/// reconciliation is composed entirely through `SyncEngine.startSync` +
/// `SyncEngine.flushNow`, so the outbox's own storage details stay inside
/// Phase 2 (phase-03 Design Constraints: "the repository itself has no
/// outbox dependency" applies equally to this Bloc).
class ExamAttemptBloc extends Bloc<ExamAttemptEvent, ExamAttemptState> {
  ExamAttemptBloc({
    required ExamAttemptRepository repository,
    required SessionEntryRepository sessionEntryRepository,
    required SyncEngine syncEngine,
    required TimerService timerService,
    required MediaUploadCoordinator mediaUploadCoordinator,
    required LockdownService lockdownService,
    required HeartbeatService heartbeatService,
  }) : _repository = repository,
       _sessionEntryRepository = sessionEntryRepository,
       _syncEngine = syncEngine,
       _timerService = timerService,
       _mediaUploadCoordinator = mediaUploadCoordinator,
       _lockdownService = lockdownService,
       _heartbeatService = heartbeatService,
       super(const AttemptIdle()) {
    on<SessionResolutionRequested>(_onSessionResolutionRequested);
    on<NextTaskRequested>(_onNextTaskRequested);
    on<NavigateTaskRequested>(_onNavigateTaskRequested);
    on<TimerSnapshotUpdated>(_onTimerSnapshotUpdated);
    on<TimerTaskAdvancedExternally>(_onTimerTaskAdvancedExternally);
    on<SyncTaskRejectedExternally>(_onSyncTaskRejectedExternally);
    on<ForceSubmitRequested>(_onForceSubmitRequested);
    on<DevPreviewAttemptSeeded>(_onDevPreviewAttemptSeeded);
    on<AppResumed>(_onAppResumed);
    _timerTicksSubscription = _timerService.ticks.listen(
      (snapshot) => add(TimerSnapshotUpdated(snapshot)),
    );
    _taskAdvancedSubscription = _timerService.taskAdvancedExternally.listen(
      (_) => add(const TimerTaskAdvancedExternally()),
    );
    _taskRejectedSubscription = _syncEngine.taskRejectedExternally.listen(
      (_) => add(const SyncTaskRejectedExternally()),
    );
  }

  final ExamAttemptRepository _repository;
  final SessionEntryRepository _sessionEntryRepository;
  final SyncEngine _syncEngine;
  final TimerService _timerService;
  final MediaUploadCoordinator _mediaUploadCoordinator;
  final LockdownService _lockdownService;
  final HeartbeatService _heartbeatService;
  late final StreamSubscription<TimerSnapshot> _timerTicksSubscription;
  late final StreamSubscription<void> _taskAdvancedSubscription;
  late final StreamSubscription<void> _taskRejectedSubscription;

  /// Tracks the running attempt so a stray `NextTaskRequested` after
  /// completion (or before any attempt started) is a no-op, not a crash.
  String? _attemptPublicId;

  /// The `reason` of the most recently handled `NextTaskRequested` — read
  /// by `_completeAttempt` so `AttemptCompleted.timeExpired` reflects
  /// whether this completion was reached via the auto time's-up advance or
  /// a normal one. Never read for `ForceSubmitRequested`'s own completion
  /// path (force-submit is always user-initiated, never time-triggered).
  AdvanceReason _lastAdvanceReason = AdvanceReason.manual;

  /// Synchronous re-entrancy guard for [_onForceSubmitRequested] — `bloc`'s
  /// default `EventTransformer` is concurrent, so a manual tap
  /// (`ExamAppBar`'s confirm dialog is async and its button is never
  /// disabled mid-submit) can race the exam-clock-zero auto-trigger added in
  /// [_onTimerSnapshotUpdated] (client-side-exam-timer Phase 4, code review
  /// finding): both handlers could otherwise pass the `_attemptPublicId !=
  /// null` check before either's `await _repository.forceSubmit` resolves,
  /// firing the request twice — the loser gets `AttemptAlreadyCompleteException`
  /// from the server and would overwrite an already-emitted `AttemptCompleted`
  /// with `AttemptError`. Set/cleared synchronously (never across an
  /// `await`), so the second concurrent invocation sees it before making any
  /// network call at all.
  bool _forceSubmitInFlight = false;

  Future<void> _onSessionResolutionRequested(
    SessionResolutionRequested event,
    Emitter<ExamAttemptState> emit,
  ) async {
    emit(const AttemptStarting());
    String? sessionPublicId;
    try {
      sessionPublicId = await _sessionEntryRepository.resolveSessionPublicId(
        event.rawInput,
      );
      final response = event.deviceCheckConfirmed
          ? await _repository.startOrResumeAttempt(
              sessionPublicId,
              deviceCheckConfirmed: true,
            )
          : await _repository.startOrResumeAttempt(sessionPublicId);
      // Guarded by `response.task != null` too, not just `!completed` —
      // a contract-violating completed:false/task:null response must
      // never arm SyncEngine, or it's left running for an attempt that
      // _emitFromResponse below is about to reject as an error, orphaning
      // a background sync session and crashing the next legitimate
      // startSync (QUAL-302, Phase 3 quality gate).
      if (!response.completed && response.task != null) {
        // Lockdown activation runs *before* SyncEngine is armed so the
        // attempt never starts observing timer/canary events while the
        // student's clipboard is still wide open. A failure here aborts
        // the entire start — STRICT-mode attempts MUST NOT begin if
        // fullscreen/shortcut/clipboard hooks aren't installed.
        await _activateLockdownForResponse(response);

        // Resume reconciliation: any Phase 2 outbox rows left over from a
        // prior app session for this attempt get an immediate flush
        // attempt, rather than passively waiting on the next canary event
        // or periodic tick (phase-03 Design Constraints). startSync alone
        // only arms future triggers; flushNow is what makes the attempt
        // actually immediate.
        _syncEngine.startSync(
          response.attemptPublicId,
          encryptionPublicKey: response.encryptionPublicKey,
        );
        await _syncEngine.flushNow(response.attemptPublicId);
      }
      await _emitFromResponse(response, emit);
    } on LockdownActivationException catch (e) {
      // STRICT/STANDARD activation failed. Surface as an
      // [AttemptError] so the UI can render the failure dialog; do
      // NOT touch SyncEngine — nothing was started yet.
      emit(AttemptError(e));
    } catch (e) {
      // Any failure here — SessionResolutionException, a mapped
      // ApiException, or an unexpected shape error from a malformed
      // response — must still reach AttemptError; otherwise the bloc is
      // stranded in AttemptStarting forever (QUAL-301, Phase 3 quality
      // gate, mirroring Phase 1's AuthBloc QUAL-103 fix).
      if (e is ConflictException &&
          e.message == 'DEVICE_CHECK_REQUIRED' &&
          !event.deviceCheckConfirmed &&
          sessionPublicId != null) {
        emit(DeviceCheckRequired(sessionPublicId));
      } else {
        emit(AttemptError(_asAttemptException(e)));
      }
    }
  }

  /// Maps the response's `lockdownMode` (Phase 1 wire value) to the
  /// service's [LockdownMode] enum and activates accordingly. `none` /
  /// null are silent no-ops. Anything else surfaces as a
  /// [LockdownActivationException] the caller catches.
  Future<void> _activateLockdownForResponse(
    AttemptTaskResponse response,
  ) async {
    final wire = response.lockdownMode;
    final mode = wire == null
        ? LockdownMode.none
        : LockdownMode.fromString(wire);
    if (mode == LockdownMode.none) return;
    await _lockdownService.activateLockdown(
      mode: mode,
      attemptPublicId: response.attemptPublicId,
    );
  }

  void _onNextTaskRequested(
    NextTaskRequested event,
    Emitter<ExamAttemptState> emit,
  ) {
    final currentState = state;
    if (currentState is! AttemptInProgress) return;
    _lastAdvanceReason = event.reason;

    final nextIndex = currentState.currentIndex + 1;
    if (nextIndex >= currentState.allTasks.length) {
      add(ForceSubmitRequested(reason: event.reason));
      return;
    }

    final nextTask = currentState.allTasks[nextIndex];
    _syncEngine.setActiveTask(nextTask.pinnedItemPublicId);
    _timerService.seedFromTask(nextTask);
    _timerService.startPolling(currentState.attemptPublicId);
    _heartbeatService.start(currentState.attemptPublicId);
    emit(currentState.copyWith(
      currentIndex: nextIndex,
      timerSnapshot: _timerService.currentSnapshot,
    ));
  }

  void _onNavigateTaskRequested(
    NavigateTaskRequested event,
    Emitter<ExamAttemptState> emit,
  ) {
    final currentState = state;
    if (currentState is! AttemptInProgress) return;
    _lastAdvanceReason = AdvanceReason.manual;

    final fromIndex = currentState.allTasks.indexWhere(
      (t) => t.pinnedItemPublicId == event.fromPinnedItemPublicId,
    );
    if (fromIndex < 0) return;

    final targetIndex = fromIndex +
        (event.direction == TaskNavigationDirection.next ? 1 : -1);
    if (targetIndex < 0 || targetIndex >= currentState.allTasks.length) return;

    final targetTask = currentState.allTasks[targetIndex];
    _syncEngine.setActiveTask(targetTask.pinnedItemPublicId);
    _timerService.seedFromTask(targetTask);
    _timerService.startPolling(currentState.attemptPublicId);
    _heartbeatService.start(currentState.attemptPublicId);
    emit(currentState.copyWith(
      currentIndex: targetIndex,
      timerSnapshot: _timerService.currentSnapshot,
    ));
  }

  Exception _asAttemptException(Object error) =>
      error is Exception ? error : UnknownApiException(error.toString());

  /// Also wires the whole-attempt local countdown reaching zero to the same
  /// force-submit path a manual tap uses (client-side-exam-timer Phase 4,
  /// FR-05) — no server-side deadline check to block it now that server-side
  /// enforcement is gone entirely, so the client is the only thing that can
  /// close out the attempt when the exam clock runs out. Edge-triggered
  /// (fires once, on the >0 -> ==0 transition) rather than on every
  /// subsequent zero tick — also correctly never fires at all for an
  /// attempt predating `examEndTime` (its `examRemaining` is always zero
  /// from the very first tick, so this transition never happens).
  void _onTimerSnapshotUpdated(
    TimerSnapshotUpdated event,
    Emitter<ExamAttemptState> emit,
  ) {
    final currentState = state;
    if (currentState is! AttemptInProgress) return;
    final examJustExpired =
        event.snapshot.examRemaining == Duration.zero &&
        currentState.timerSnapshot.examRemaining > Duration.zero;
    emit(currentState.copyWith(timerSnapshot: event.snapshot));
    if (examJustExpired) {
      add(const ForceSubmitRequested());
    }
  }

  void _onTimerTaskAdvancedExternally(
    TimerTaskAdvancedExternally event,
    Emitter<ExamAttemptState> emit,
  ) {
    _onNextTaskRequested(const NextTaskRequested(), emit);
  }

  void _onSyncTaskRejectedExternally(
    SyncTaskRejectedExternally event,
    Emitter<ExamAttemptState> emit,
  ) {
    _onNextTaskRequested(const NextTaskRequested(), emit);
  }

  Future<void> _onForceSubmitRequested(
    ForceSubmitRequested event,
    Emitter<ExamAttemptState> emit,
  ) async {
    final attemptPublicId = _attemptPublicId;
    if (attemptPublicId == null || _forceSubmitInFlight) return;
    _forceSubmitInFlight = true;
    _lastAdvanceReason = event.reason;
    try {
      final response = await _repository.forceSubmit(attemptPublicId);
      // Same terminal outcome as the natural end-of-tasks path in
      // _emitFromResponse — force-submit and running out of tasks are
      // indistinguishable from the UI's perspective (phase-07 Design
      // Constraints).
      await _completeAttempt(
        attemptPublicId,
        emit,
        attemptNumber: response.attemptNumber,
        remainingRetries: response.remainingRetries,
        canRetry: response.canRetry,
      );
    } catch (e) {
      emit(AttemptError(_asAttemptException(e)));
    } finally {
      _forceSubmitInFlight = false;
    }
  }

  /// Re-fetches all tasks from the server to get fresh timer values, then
  /// re-emits `AttemptInProgress` with the refreshed list. Preserves the
  /// student's current position by matching `pinnedItemPublicId`. Falls back
  /// to simply re-arming the timer if `fetchAllTasks` fails.
  Future<void> _onAppResumed(
    AppResumed event,
    Emitter<ExamAttemptState> emit,
  ) async {
    final attemptPublicId = _attemptPublicId;
    if (attemptPublicId == null) return;

    final currentState = state;
    if (currentState is! AttemptInProgress) {
      _timerService.startPolling(attemptPublicId);
      return;
    }

    try {
      final responses = await _repository.fetchAllTasks(attemptPublicId);
      final freshTasks = responses
          .where((r) => !r.completed && r.task != null)
          .map((r) => r.task!)
          .toList();

      if (freshTasks.isEmpty) {
        _timerService.startPolling(attemptPublicId);
        return;
      }

      final currentPinnedId = currentState.task.pinnedItemPublicId;
      final resumeIndex = freshTasks.indexWhere(
        (t) => t.pinnedItemPublicId == currentPinnedId,
      );
      final safeIndex = resumeIndex < 0 ? 0 : resumeIndex;
      final resumeTask = freshTasks[safeIndex];

      _syncEngine.setActiveTask(resumeTask.pinnedItemPublicId);
      _timerService.seedFromTask(resumeTask);
      _timerService.startPolling(attemptPublicId);
      emit(currentState.copyWith(
        allTasks: freshTasks,
        currentIndex: safeIndex,
        timerSnapshot: _timerService.currentSnapshot,
      ));
    } catch (_) {
      _timerService.startPolling(attemptPublicId);
    }
  }

  /// Shared terminal teardown for both the natural end-of-tasks path
  /// ([_emitFromResponse]) and [_onForceSubmitRequested] — kept as one
  /// place so the two paths can't drift out of sync (phase-07 Design
  /// Constraints: force-submit must reach the identical terminal state).
  Future<void> _completeAttempt(
    String attemptPublicId,
    Emitter<ExamAttemptState> emit, {
    int attemptNumber = 1,
    int remainingRetries = 0,
    bool canRetry = false,
  }) async {
    _attemptPublicId = null;
    _syncEngine.setActiveTask(null);
    _syncEngine.stopSync();
    _timerService.stop();
    _heartbeatService.stop();
    _mediaUploadCoordinator.stop();
    // Tear down lockdown AFTER the academic-flow stop chain so a
    // fullscreen/clipboard platform call that errors doesn't leave the
    // student's UI in a half-restored state while the timer is still
    // ticking (phase-04 Design Constraints). Teardown itself is
    // idempotent — running it twice in a row is a no-op.
    try {
      await _lockdownService.deactivateLockdown();
    } on Object catch (_) {
      // Lockdown teardown must never throw out of this path — the
      // attempt is terminal, the student's screen state must reflect
      // that even if a platform call glitched on the way out.
    }
    final timeExpired = _lastAdvanceReason == AdvanceReason.timeExpired;
    _lastAdvanceReason = AdvanceReason.manual;
    emit(
      AttemptCompleted(
        attemptPublicId,
        timeExpired: timeExpired,
        attemptNumber: attemptNumber,
        remainingRetries: remainingRetries,
        canRetry: canRetry,
      ),
    );
  }

  Future<void> _emitFromResponse(
    AttemptTaskResponse response,
    Emitter<ExamAttemptState> emit,
  ) async {
    if (response.completed) {
      await _completeAttempt(
        response.attemptPublicId,
        emit,
        attemptNumber: response.attemptNumber,
        remainingRetries: response.remainingRetries,
        canRetry: response.canRetry,
      );
      return;
    }

    final task = response.task;
    if (task == null) {
      // Contract violation (completed:false with no task) — surfaced as
      // an error rather than crash-dereferencing a null task.
      emit(
        const AttemptError(
          UnknownApiException(
            'Attempt response missing task while not completed.',
          ),
        ),
      );
      return;
    }

    _attemptPublicId = response.attemptPublicId;

    // Prefetch all tasks so local navigation needs no server round-trips.
    // Falls back to single-task mode on error — exam still runs correctly.
    List<TaskView> allTasks;
    try {
      final responses = await _repository.fetchAllTasks(response.attemptPublicId);
      allTasks = responses
          .where((r) => !r.completed && r.task != null)
          .map((r) => r.task!)
          .toList();
      if (allTasks.isEmpty) allTasks = [task];
    } catch (_) {
      allTasks = [task];
    }

    final currentIndex = allTasks.indexWhere(
      (t) => t.pinnedItemPublicId == task.pinnedItemPublicId,
    );
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;

    _syncEngine.setActiveTask(task.pinnedItemPublicId);
    // Started on every in-progress transition, not just the first — a
    // no-op while already running (MediaUploadCoordinator.start()'s own
    // guard), so any READ_ALOUD row left over from a prior app session
    // resumes its background canary/periodic retry loop rather than being
    // limited to whatever attempt was running when it was first recorded
    // (phase-06 Design Constraints).
    _mediaUploadCoordinator.start();
    _timerService.seedFromTask(task);
    _timerService.startPolling(response.attemptPublicId);
    // 15s heartbeat, independent of TimerService's per-task lifecycle and
    // SyncEngine's active-task exclusion (client-side-exam-timer Phase 4) —
    // called on every in-progress transition like the two services above,
    // but HeartbeatService.start is itself idempotent for the same attempt
    // (its own doc comment), so this never restarts the cadence per task.
    _heartbeatService.start(response.attemptPublicId);
    emit(
      AttemptInProgress(
        response.attemptPublicId,
        task,
        _timerService.currentSnapshot,
        allTasks: allTasks,
        currentIndex: safeIndex,
        examMode: response.examMode,
      ),
    );
  }

  /// `kDebugMode`-only path (see [DevPreviewAttemptSeeded]'s doc) — same
  /// seeding [_emitFromResponse] does for a real in-progress response, minus
  /// the `completed`/`task == null` branches a fixture never needs. Works
  /// against the fake `dev-preview-attempt` ID with no real backend at all
  /// (client-side-exam-timer Phase 3): `TimerService` no longer makes any
  /// network call — `startPolling` just arms the local tick/phase-transition
  /// timers against whatever `seedFromTask` already computed.
  void _onDevPreviewAttemptSeeded(
    DevPreviewAttemptSeeded event,
    Emitter<ExamAttemptState> emit,
  ) {
    const attemptPublicId = 'dev-preview-attempt';
    _attemptPublicId = attemptPublicId;
    _syncEngine.setActiveTask(event.task.pinnedItemPublicId);
    _mediaUploadCoordinator.start();
    _timerService.seedFromTask(event.task);
    _timerService.startPolling(attemptPublicId);
    // Not heartbeatService.start() here, unlike _emitFromResponse — this is
    // a fake, backend-less fixture id (code review finding: pinging the real
    // endpoint every 15s for an attempt that doesn't exist just produces
    // recurring warning-log noise during dev preview, with no upside).
    emit(
      AttemptInProgress(
        attemptPublicId,
        event.task,
        _timerService.currentSnapshot,
        examMode: 'PRACTICE',
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_timerTicksSubscription.cancel());
    unawaited(_taskAdvancedSubscription.cancel());
    unawaited(_taskRejectedSubscription.cancel());
    // Best-effort: if the bloc is being torn down while a lockdown
    // session is still active (force-quit, hot-restart, etc.) we want
    // the window back to a normal state. Errors are silently ignored
    // because there's no UI to surface them on at this point.
    unawaited(_lockdownService.deactivateLockdown());
    _heartbeatService.dispose();
    return super.close();
  }
}
