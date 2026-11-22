/// Timing rules for the forward-only Next action.
abstract final class ExamAttemptNavigationConstants {
  /// A manual Next tap is ignored (button disabled, bloc event dropped) for
  /// this long after a task becomes active, so a fast double tap cannot skip
  /// the next task unread. Timer/auto advances are not blocked by it.
  static const Duration nextCooldown = Duration(milliseconds: 800);

  /// After a Next was dispatched the button stays locked until the new task
  /// appears. If the bloc ignored the event (for example a failed task-list
  /// reload) the lock is released after this long so the student can retry.
  static const Duration advanceSettleTimeout = Duration(seconds: 5);

  /// Upper bound on a screen's "before leaving" work (stopping the recorder)
  /// so a stuck plugin can never block Next. It never waits for a network call.
  static const Duration leaveHookTimeout = Duration(seconds: 2);
}
