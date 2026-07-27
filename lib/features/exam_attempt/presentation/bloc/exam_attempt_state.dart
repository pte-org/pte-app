import '../../domain/task_view.dart';
import '../../domain/timer_snapshot.dart';

/// Separate immutable classes, no boolean-flag shape — `AttemptCompleted`
/// is its own first-class terminal state, never inferred by checking
/// `task == null` on a generic state (phase-03 Design Constraints).
sealed class ExamAttemptState {
  const ExamAttemptState();
}

final class AttemptIdle extends ExamAttemptState {
  const AttemptIdle();
}

final class AttemptStarting extends ExamAttemptState {
  const AttemptStarting();
}

final class AttemptInProgress extends ExamAttemptState {
  const AttemptInProgress(this.attemptPublicId, this.task, this.timerSnapshot);

  final String attemptPublicId;
  final TaskView task;
  final TimerSnapshot timerSnapshot;
}

final class AttemptCompleted extends ExamAttemptState {
  const AttemptCompleted(this.attemptPublicId);

  final String attemptPublicId;
}

/// Carries either a Phase 1 [ApiException] (attempt-lifecycle call
/// failed) or this feature's `SessionResolutionException` (session ID
/// couldn't be resolved) — both reach the same error state, per phase-03
/// Design Constraints ("the same error state any other repository
/// failure produces").
final class AttemptError extends ExamAttemptState {
  const AttemptError(this.error);

  final Exception error;
}
