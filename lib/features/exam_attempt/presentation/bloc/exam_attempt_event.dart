sealed class ExamAttemptEvent {
  const ExamAttemptEvent();
}

/// Resolves a session ID via `SessionEntryRepository`, then starts or
/// resumes the attempt for it.
final class SessionResolutionRequested extends ExamAttemptEvent {
  const SessionResolutionRequested();
}

/// Advances to the next task for the currently running attempt. A no-op
/// (not a crash) if dispatched with no attempt running — e.g. a stray
/// event arriving after `AttemptCompleted` (phase-03 Design Constraints).
final class NextTaskRequested extends ExamAttemptEvent {
  const NextTaskRequested();
}
