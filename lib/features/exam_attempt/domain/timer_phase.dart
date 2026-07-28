/// Which countdown phase a task is currently in — derived once from a bare
/// `TaskView` at bootstrap, then adopted directly from the server's own
/// `TimerStateResponse.phase` on every later reconciliation (phase-04
/// Design Constraints).
enum TimerPhase { prep, response }
