import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../data/repositories/exam_attempt_repository.dart';
import '../../domain/entities/exam_attempt_state.dart';
import 'exam_attempt_event.dart';

/// Orchestrates a single exam attempt: loads it, accepts answers
/// (write-first to the outbox, per FR-03), tracks the timer and sync
/// status, and submits. Skeleton-level per Phase 6 — no exam UI logic
/// lives here, only the state machine and its wiring to core services.
class ExamAttemptBloc extends Bloc<ExamAttemptEvent, ExamAttemptState> {
  ExamAttemptBloc({
    required ExamAttemptRepository repository,
    required SyncEngine syncEngine,
  }) : _repository = repository,
       _syncEngine = syncEngine,
       super(const ExamAttemptLoading()) {
    on<StartExamAttemptEvent>(_onStartExamAttempt);
    on<AnswerQuestionEvent>(_onAnswerQuestion);
    on<FinishPartEvent>(_onFinishPart);
    on<SubmitExamEvent>(_onSubmitExam);
    on<TimerTickEvent>(_onTimerTick);
    on<SyncStatusChangedEvent>(_onSyncStatusChanged);
    on<ConnectivityChangedEvent>(_onConnectivityChanged);
  }

  final ExamAttemptRepository _repository;
  final SyncEngine _syncEngine;

  Future<void> _onStartExamAttempt(
    StartExamAttemptEvent event,
    Emitter<ExamAttemptState> emit,
  ) async {
    final examState = await _repository.startAttempt(event.examId);
    _syncEngine.startSync(examState.attemptId);
    emit(
      ExamAttemptInProgress(
        attemptId: examState.attemptId,
        currentPartId: examState.currentPartId,
        questionsAnswered: 0,
        timeRemaining: examState.timeRemaining,
        pendingAnswerCount: 0,
        failedAnswerCount: 0,
      ),
    );
  }

  Future<void> _onAnswerQuestion(
    AnswerQuestionEvent event,
    Emitter<ExamAttemptState> emit,
  ) async {
    final current = state;
    final attemptId = _attemptIdOf(current);
    if (attemptId == null) return;

    await _repository.saveAnswerLocally(
      attemptId: attemptId,
      questionId: event.questionId,
      content: event.content,
    );

    switch (current) {
      case ExamAttemptInProgress():
        emit(
          current.copyWith(
            questionsAnswered: current.questionsAnswered + 1,
            pendingAnswerCount: current.pendingAnswerCount + 1,
          ),
        );
      case ExamAttemptOffline():
        emit(
          current.copyWith(pendingAnswerCount: current.pendingAnswerCount + 1),
        );
      case ExamAttemptLoading():
      case ExamAttemptSyncing():
      case ExamAttemptError():
      case ExamAttemptSubmitted():
        break;
    }
  }

  void _onFinishPart(FinishPartEvent event, Emitter<ExamAttemptState> emit) {
    // Skeleton: advancing currentPartId is future feature work (see
    // README "Known Gaps") — pending answers remain queued and resumable
    // regardless of which part is "current".
  }

  Future<void> _onSubmitExam(
    SubmitExamEvent event,
    Emitter<ExamAttemptState> emit,
  ) async {
    final attemptId = _attemptIdOf(state);
    if (attemptId == null) return;

    try {
      await _repository.finishAttempt(attemptId);
      // stopSync() must run before Submitted is emitted: there is no
      // point flushing answers for an attempt the server has already
      // closed (Step 3e) — the SyncEngine reentry guard (Phase 5) is the
      // complementary, not substitute, safeguard.
      _syncEngine.stopSync();
      emit(ExamAttemptSubmitted(attemptId));
    } on ConflictException {
      emit(const ExamAttemptError('This exam part has already been closed.'));
    }
  }

  void _onTimerTick(TimerTickEvent event, Emitter<ExamAttemptState> emit) {
    final current = state;
    if (current is ExamAttemptInProgress) {
      emit(
        current.copyWith(
          timeRemaining: Duration(seconds: event.timeRemainingSeconds),
        ),
      );
    }
  }

  void _onSyncStatusChanged(
    SyncStatusChangedEvent event,
    Emitter<ExamAttemptState> emit,
  ) {
    final current = state;
    if (current is ExamAttemptInProgress) {
      emit(
        current.copyWith(
          pendingAnswerCount: event.pendingCount,
          failedAnswerCount: event.failedCount,
        ),
      );
    }
  }

  void _onConnectivityChanged(
    ConnectivityChangedEvent event,
    Emitter<ExamAttemptState> emit,
  ) {
    final current = state;
    if (!event.isOnline && current is ExamAttemptInProgress) {
      emit(
        ExamAttemptOffline(
          attemptId: current.attemptId,
          currentPartId: current.currentPartId,
          questionsAnswered: current.questionsAnswered,
          timeRemaining: current.timeRemaining,
          pendingAnswerCount: current.pendingAnswerCount,
          failedAnswerCount: current.failedAnswerCount,
        ),
      );
    } else if (event.isOnline && current is ExamAttemptOffline) {
      emit(
        ExamAttemptInProgress(
          attemptId: current.attemptId,
          currentPartId: current.currentPartId,
          questionsAnswered: current.questionsAnswered,
          timeRemaining: current.timeRemaining,
          pendingAnswerCount: current.pendingAnswerCount,
          failedAnswerCount: current.failedAnswerCount,
        ),
      );
    }
  }

  String? _attemptIdOf(ExamAttemptState state) {
    return switch (state) {
      ExamAttemptInProgress(attemptId: final id) => id,
      ExamAttemptOffline(attemptId: final id) => id,
      ExamAttemptSyncing(attemptId: final id) => id,
      ExamAttemptLoading() ||
      ExamAttemptError() ||
      ExamAttemptSubmitted() => null,
    };
  }
}
