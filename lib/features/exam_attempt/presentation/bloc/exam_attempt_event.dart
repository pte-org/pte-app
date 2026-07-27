sealed class ExamAttemptEvent {
  const ExamAttemptEvent();
}

/// Resolves [rawInput] into a session ID via `SessionEntryRepository`,
/// then starts or resumes the attempt for it. `rawInput`'s meaning is
/// entirely owned by whichever `SessionEntryRepository` is registered
/// (raw manual text today; a deep-link URI or a picked list item's ID
/// later) — this event only carries it through untouched.
final class SessionResolutionRequested extends ExamAttemptEvent {
  const SessionResolutionRequested({required this.rawInput});

  final String rawInput;
}

/// Advances to the next task for the currently running attempt. A no-op
/// (not a crash) if dispatched with no attempt running — e.g. a stray
/// event arriving after `AttemptCompleted` (phase-03 Design Constraints).
final class NextTaskRequested extends ExamAttemptEvent {
  const NextTaskRequested();
}
