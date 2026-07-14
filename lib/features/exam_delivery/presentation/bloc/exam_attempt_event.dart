import 'package:equatable/equatable.dart';

/// Inputs the exam-delivery Bloc reacts to. Sealed alongside
/// [ExamAttemptState] (`exam_attempt_state.dart`) so every `on<Event>`
/// handler set in [ExamAttemptBloc] is exhaustiveness-checked the same way.
sealed class ExamAttemptEvent extends Equatable {
  const ExamAttemptEvent();
}

/// Loads (or creates) the attempt for [examId] and transitions to
/// [ExamAttemptInProgress] once the server confirms.
class StartExamAttemptEvent extends ExamAttemptEvent {
  const StartExamAttemptEvent(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}

/// User answered [questionId]. Always written to the outbox DAO first
/// (Phase 2), before any network attempt — "answered = saved" holds even
/// offline, per FR-03.
class AnswerQuestionEvent extends ExamAttemptEvent {
  const AnswerQuestionEvent({required this.questionId, required this.content});

  final String questionId;
  final String content;

  @override
  List<Object?> get props => [questionId, content];
}

/// User finished the current part. Skeleton-level: part-advance logic is
/// future work (see README "Known Gaps").
class FinishPartEvent extends ExamAttemptEvent {
  const FinishPartEvent();

  @override
  List<Object?> get props => [];
}

/// User submits the whole exam. On success, `syncEngine.stopSync()` must
/// run before [ExamAttemptSubmitted] is emitted (Step 3e) — there is no
/// point flushing answers for an attempt the server has already closed.
class SubmitExamEvent extends ExamAttemptEvent {
  const SubmitExamEvent();

  @override
  List<Object?> get props => [];
}

/// Forwarded from `TimerService.ticks` (Phase 4) — re-renders the
/// countdown without touching any other field.
class TimerTickEvent extends ExamAttemptEvent {
  const TimerTickEvent(this.timeRemainingSeconds);

  final int timeRemainingSeconds;

  @override
  List<Object?> get props => [timeRemainingSeconds];
}

/// Forwarded from `SyncEngine`/outbox observation — updates the
/// pending/failed answer counters shown in the UI.
class SyncStatusChangedEvent extends ExamAttemptEvent {
  const SyncStatusChangedEvent({
    required this.pendingCount,
    required this.failedCount,
  });

  final int pendingCount;
  final int failedCount;

  @override
  List<Object?> get props => [pendingCount, failedCount];
}

/// Forwarded from the network canary (Phase 5) — toggles
/// [ExamAttemptInProgress]/[ExamAttemptOffline] without ever blocking input.
class ConnectivityChangedEvent extends ExamAttemptEvent {
  const ConnectivityChangedEvent({required this.isOnline});

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}
