import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';

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

/// The server requires the student's pre-exam microphone/sound check before
/// the attempt can be created. The UI uses the carried session ID to retry
/// the same request after both checks are confirmed.
final class DeviceCheckRequired extends ExamAttemptState {
  const DeviceCheckRequired(this.sessionPublicId);

  final String sessionPublicId;
}

final class AttemptInProgress extends ExamAttemptState {
  AttemptInProgress(
    this.attemptPublicId,
    TaskView singleTask,
    this.timerSnapshot, {
    List<TaskView>? allTasks,
    this.currentIndex = 0,
    this.examMode,
  }) : allTasks = allTasks ?? [singleTask];

  final String attemptPublicId;

  /// Full prefetched task list for the attempt, in order. Single-item when
  /// `fetchAllTasks` was unavailable or the attempt was created in dev-preview
  /// mode — local navigation is still correct, just limited to one task.
  final List<TaskView> allTasks;

  /// Index into [allTasks] for the currently displayed task.
  final int currentIndex;

  final TimerSnapshot timerSnapshot;

  /// Wire value from server — `"PRACTICE"` or `"OFFICIAL_EXAM"`. Null only
  /// for legacy attempts. Consumers treat null as `"OFFICIAL_EXAM"`.
  final String? examMode;

  bool get isPractice => examMode == 'PRACTICE';

  TaskView get task => allTasks[currentIndex];

  AttemptInProgress copyWith({
    List<TaskView>? allTasks,
    int? currentIndex,
    TimerSnapshot? timerSnapshot,
  }) {
    final newAllTasks = allTasks ?? this.allTasks;
    final newIndex = currentIndex ?? this.currentIndex;
    return AttemptInProgress(
      attemptPublicId,
      newAllTasks[newIndex],
      timerSnapshot ?? this.timerSnapshot,
      allTasks: newAllTasks,
      currentIndex: newIndex,
      examMode: examMode,
    );
  }
}

final class AttemptCompleted extends ExamAttemptState {
  const AttemptCompleted(
    this.attemptPublicId, {
    this.timeExpired = false,
    this.attemptNumber = 1,
    this.remainingRetries = 0,
    this.canRetry = false,
  });

  final String attemptPublicId;

  /// True when this attempt ended because a section's shared countdown hit
  /// zero (`AdvanceReason.timeExpired`), false for a normal
  /// answered-the-last-task completion — client-derived, not
  /// server-confirmed (only affects which message `SectionCompletedScreen`
  /// shows, never scoring).
  final bool timeExpired;
  final int attemptNumber;
  final int remainingRetries;
  final bool canRetry;
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
