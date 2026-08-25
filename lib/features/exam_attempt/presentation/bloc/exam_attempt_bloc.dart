import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';
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
  })  : _repository = repository,
        _sessionEntryRepository = sessionEntryRepository,
        _syncEngine = syncEngine,
        _timerService = timerService,
        _mediaUploadCoordinator = mediaUploadCoordinator,
        super(const AttemptIdle()) {
    on<SessionResolutionRequested>(_onSessionResolutionRequested);
    on<NextTaskRequested>(_onNextTaskRequested);
    on<TimerSnapshotUpdated>(_onTimerSnapshotUpdated);
    on<TimerTaskAdvancedExternally>(_onTimerTaskAdvancedExternally);
    on<SyncTaskRejectedExternally>(_onSyncTaskRejectedExternally);
    on<ForceSubmitRequested>(_onForceSubmitRequested);
    on<AppResumed>(_onAppResumed);
    _timerTicksSubscription = _timerService.ticks.listen((snapshot) => add(TimerSnapshotUpdated(snapshot)));
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

  Future<void> _onSessionResolutionRequested(
    SessionResolutionRequested event,
    Emitter<ExamAttemptState> emit,
  ) async {
    emit(const AttemptStarting());
    try {
      final sessionPublicId = await _sessionEntryRepository.resolveSessionPublicId(event.rawInput);
      final response = await _repository.startOrResumeAttempt(sessionPublicId);
      // Guarded by `response.task != null` too, not just `!completed` —
      // a contract-violating completed:false/task:null response must
      // never arm SyncEngine, or it's left running for an attempt that
      // _emitFromResponse below is about to reject as an error, orphaning
      // a background sync session and crashing the next legitimate
      // startSync (QUAL-302, Phase 3 quality gate).
      if (!response.completed && response.task != null) {
        // Resume reconciliation: any Phase 2 outbox rows left over from a
        // prior app session for this attempt get an immediate flush
        // attempt, rather than passively waiting on the next canary event
        // or periodic tick (phase-03 Design Constraints). startSync alone
        // only arms future triggers; flushNow is what makes the attempt
        // actually immediate.
        _syncEngine.startSync(response.attemptPublicId);
        await _syncEngine.flushNow(response.attemptPublicId);
      }
      _emitFromResponse(response, emit);
    } catch (e) {
      // Any failure here — SessionResolutionException, a mapped
      // ApiException, or an unexpected shape error from a malformed
      // response — must still reach AttemptError; otherwise the bloc is
      // stranded in AttemptStarting forever (QUAL-301, Phase 3 quality
      // gate, mirroring Phase 1's AuthBloc QUAL-103 fix).
      emit(AttemptError(_asAttemptException(e)));
    }
  }

  Future<void> _onNextTaskRequested(NextTaskRequested event, Emitter<ExamAttemptState> emit) async {
    final attemptPublicId = _attemptPublicId;
    if (attemptPublicId == null) return;
    _lastAdvanceReason = event.reason;
    try {
      final response = await _repository.fetchNextTask(attemptPublicId);
      _emitFromResponse(response, emit);
    } catch (e) {
      emit(AttemptError(_asAttemptException(e)));
    }
  }

  Exception _asAttemptException(Object error) => error is Exception ? error : UnknownApiException(error.toString());

  void _onTimerSnapshotUpdated(TimerSnapshotUpdated event, Emitter<ExamAttemptState> emit) {
    final currentState = state;
    if (currentState is! AttemptInProgress) return;
    emit(AttemptInProgress(currentState.attemptPublicId, currentState.task, event.snapshot));
  }

  Future<void> _onTimerTaskAdvancedExternally(
    TimerTaskAdvancedExternally event,
    Emitter<ExamAttemptState> emit,
  ) {
    // A proctor-initiated (or otherwise external) task advance must not be
    // trusted as "still the currently displayed task" — re-fetch through
    // the same path a normal NextTaskRequested would (phase-04 Design
    // Constraints).
    return _onNextTaskRequested(const NextTaskRequested(), emit);
  }

  Future<void> _onSyncTaskRejectedExternally(
    SyncTaskRejectedExternally event,
    Emitter<ExamAttemptState> emit,
  ) {
    // The server already closed the current task out from under the
    // client (stale/expired submission) — same re-fetch path, the local
    // "current task" view is equally stale here (phase-07 Design
    // Constraints).
    return _onNextTaskRequested(const NextTaskRequested(), emit);
  }

  Future<void> _onForceSubmitRequested(ForceSubmitRequested event, Emitter<ExamAttemptState> emit) async {
    final attemptPublicId = _attemptPublicId;
    if (attemptPublicId == null) return;
    _lastAdvanceReason = AdvanceReason.manual;
    try {
      await _repository.forceSubmit(attemptPublicId);
      // Same terminal outcome as the natural end-of-tasks path in
      // _emitFromResponse — force-submit and running out of tasks are
      // indistinguishable from the UI's perspective (phase-07 Design
      // Constraints).
      _completeAttempt(attemptPublicId, emit);
    } catch (e) {
      emit(AttemptError(_asAttemptException(e)));
    }
  }

  /// Re-arms `TimerService`'s poll+tick chain immediately instead of
  /// waiting up to the normal poll interval — `startPolling` already calls
  /// `stop()` first internally, so this safely supersedes whatever chain
  /// was running, exactly as a task transition would. A no-op if no
  /// attempt is currently running (e.g. resumed while on the session-entry
  /// or report screen).
  void _onAppResumed(AppResumed event, Emitter<ExamAttemptState> emit) {
    final attemptPublicId = _attemptPublicId;
    if (attemptPublicId == null) return;
    _timerService.startPolling(attemptPublicId);
  }

  /// Shared terminal teardown for both the natural end-of-tasks path
  /// ([_emitFromResponse]) and [_onForceSubmitRequested] — kept as one
  /// place so the two paths can't drift out of sync (phase-07 Design
  /// Constraints: force-submit must reach the identical terminal state).
  void _completeAttempt(String attemptPublicId, Emitter<ExamAttemptState> emit) {
    _attemptPublicId = null;
    _syncEngine.setActiveTask(null);
    _syncEngine.stopSync();
    _timerService.stop();
    _mediaUploadCoordinator.stop();
    final timeExpired = _lastAdvanceReason == AdvanceReason.timeExpired;
    _lastAdvanceReason = AdvanceReason.manual;
    emit(AttemptCompleted(attemptPublicId, timeExpired: timeExpired));
  }

  void _emitFromResponse(AttemptTaskResponse response, Emitter<ExamAttemptState> emit) {
    if (response.completed) {
      _completeAttempt(response.attemptPublicId, emit);
      return;
    }

    final task = response.task;
    if (task == null) {
      // Contract violation (completed:false with no task) — surfaced as
      // an error rather than crash-dereferencing a null task.
      emit(const AttemptError(UnknownApiException('Attempt response missing task while not completed.')));
      return;
    }

    _attemptPublicId = response.attemptPublicId;
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
    emit(AttemptInProgress(response.attemptPublicId, task, _timerService.currentSnapshot));
  }

  @override
  Future<void> close() {
    unawaited(_timerTicksSubscription.cancel());
    unawaited(_taskAdvancedSubscription.cancel());
    unawaited(_taskRejectedSubscription.cancel());
    return super.close();
  }
}
