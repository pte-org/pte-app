import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/repositories/exam_attempt_repository.dart';
import '../../domain/repositories/session_entry_repository.dart';
import '../../domain/task_view.dart';
import 'exam_attempt_event.dart';
import 'exam_attempt_state.dart';

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
  })  : _repository = repository,
        _sessionEntryRepository = sessionEntryRepository,
        _syncEngine = syncEngine,
        super(const AttemptIdle()) {
    on<SessionResolutionRequested>(_onSessionResolutionRequested);
    on<NextTaskRequested>(_onNextTaskRequested);
  }

  final ExamAttemptRepository _repository;
  final SessionEntryRepository _sessionEntryRepository;
  final SyncEngine _syncEngine;

  /// Tracks the running attempt so a stray `NextTaskRequested` after
  /// completion (or before any attempt started) is a no-op, not a crash.
  String? _attemptPublicId;

  Future<void> _onSessionResolutionRequested(
    SessionResolutionRequested event,
    Emitter<ExamAttemptState> emit,
  ) async {
    emit(const AttemptStarting());
    try {
      final sessionPublicId = await _sessionEntryRepository.resolveSessionPublicId(event.rawInput);
      final response = await _repository.startOrResumeAttempt(sessionPublicId);
      if (!response.completed) {
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
    } on SessionResolutionException catch (e) {
      emit(AttemptError(e));
    } on ApiException catch (e) {
      emit(AttemptError(e));
    }
  }

  Future<void> _onNextTaskRequested(NextTaskRequested event, Emitter<ExamAttemptState> emit) async {
    final attemptPublicId = _attemptPublicId;
    if (attemptPublicId == null) return;
    try {
      final response = await _repository.fetchNextTask(attemptPublicId);
      _emitFromResponse(response, emit);
    } on ApiException catch (e) {
      emit(AttemptError(e));
    }
  }

  void _emitFromResponse(AttemptTaskResponse response, Emitter<ExamAttemptState> emit) {
    if (response.completed) {
      _attemptPublicId = null;
      _syncEngine.setActiveTask(null);
      _syncEngine.stopSync();
      emit(AttemptCompleted(response.attemptPublicId));
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
    emit(AttemptInProgress(response.attemptPublicId, task));
  }
}
