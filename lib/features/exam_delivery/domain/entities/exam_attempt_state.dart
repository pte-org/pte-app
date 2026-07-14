import 'package:equatable/equatable.dart';

/// Cross-product of connectivity x sync-phase x part-open/closed state for
/// an in-progress exam attempt. Sealed so every state-transition switch is
/// exhaustiveness-checked by the analyzer — missing a branch here is a
/// compile error, not a silent bug, which matters because the exam domain
/// cannot tolerate a state combination going unhandled.
sealed class ExamAttemptState extends Equatable {
  const ExamAttemptState();
}

/// No attempt loaded yet (initial state, or a fresh app start before
/// `StartExamAttemptEvent` has been handled).
class ExamAttemptLoading extends ExamAttemptState {
  const ExamAttemptLoading();

  @override
  List<Object?> get props => [];
}

/// Exam active, online, user can answer. The single state most UI renders
/// against.
class ExamAttemptInProgress extends ExamAttemptState {
  const ExamAttemptInProgress({
    required this.attemptId,
    required this.currentPartId,
    required this.questionsAnswered,
    required this.timeRemaining,
    required this.pendingAnswerCount,
    required this.failedAnswerCount,
  });

  final String attemptId;
  final String currentPartId;
  final int questionsAnswered;
  final Duration timeRemaining;
  final int pendingAnswerCount;
  final int failedAnswerCount;

  ExamAttemptInProgress copyWith({
    String? currentPartId,
    int? questionsAnswered,
    Duration? timeRemaining,
    int? pendingAnswerCount,
    int? failedAnswerCount,
  }) {
    return ExamAttemptInProgress(
      attemptId: attemptId,
      currentPartId: currentPartId ?? this.currentPartId,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      pendingAnswerCount: pendingAnswerCount ?? this.pendingAnswerCount,
      failedAnswerCount: failedAnswerCount ?? this.failedAnswerCount,
    );
  }

  @override
  List<Object?> get props => [
    attemptId,
    currentPartId,
    questionsAnswered,
    timeRemaining,
    pendingAnswerCount,
    failedAnswerCount,
  ];
}

/// Network canary (Phase 5) reports unavailable. The user can still answer
/// — writes go to the outbox exactly as in `InProgress` — this state only
/// changes what the UI shows, never what input is accepted (FR-03's
/// "never block on network loss" guarantee).
class ExamAttemptOffline extends ExamAttemptState {
  const ExamAttemptOffline({
    required this.attemptId,
    required this.currentPartId,
    required this.questionsAnswered,
    required this.timeRemaining,
    required this.pendingAnswerCount,
    required this.failedAnswerCount,
  });

  final String attemptId;
  final String currentPartId;
  final int questionsAnswered;
  final Duration timeRemaining;
  final int pendingAnswerCount;
  final int failedAnswerCount;

  ExamAttemptOffline copyWith({
    int? pendingAnswerCount,
    int? failedAnswerCount,
  }) {
    return ExamAttemptOffline(
      attemptId: attemptId,
      currentPartId: currentPartId,
      questionsAnswered: questionsAnswered,
      timeRemaining: timeRemaining,
      pendingAnswerCount: pendingAnswerCount ?? this.pendingAnswerCount,
      failedAnswerCount: failedAnswerCount ?? this.failedAnswerCount,
    );
  }

  @override
  List<Object?> get props => [
    attemptId,
    currentPartId,
    questionsAnswered,
    timeRemaining,
    pendingAnswerCount,
    failedAnswerCount,
  ];
}

/// Outbox is actively flushing (sync engine canary just fired "available").
/// Distinct from `InProgress` so the UI can show a transient sync
/// indicator without conflating "online and idle" with "online and
/// flushing" — both are valid per FR-03 but visually distinct.
class ExamAttemptSyncing extends ExamAttemptState {
  const ExamAttemptSyncing({
    required this.attemptId,
    required this.pendingAnswerCount,
  });

  final String attemptId;
  final int pendingAnswerCount;

  @override
  List<Object?> get props => [attemptId, pendingAnswerCount];
}

/// Unrecoverable error for this attempt (e.g. 409 — part already closed on
/// submit, per FR-06). No further input is meaningful; the UI surfaces
/// [message] and offers no retry for this specific failure.
class ExamAttemptError extends ExamAttemptState {
  const ExamAttemptError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Exam finished. No more input allowed. `syncEngine.stopSync()` must have
/// already been called before this state is ever emitted (Step 3e).
class ExamAttemptSubmitted extends ExamAttemptState {
  const ExamAttemptSubmitted(this.attemptId);

  final String attemptId;

  @override
  List<Object?> get props => [attemptId];
}
