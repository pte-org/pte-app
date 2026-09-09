/// Which countdown phase a task is currently in — computed entirely
/// client-side from `TaskView.prepSeconds`/`responseSeconds` and a local
/// wall-clock deadline (`TimerService.seedFromTask`), with a one-shot local
/// timer flipping `prep` -> `response` at the exact computed instant
/// (client-side-exam-timer Phase 3) — no server reconciliation of any kind
/// as of that phase; the server-side deadline/phase concept this enum used
/// to mirror was deleted entirely in Phase 5.
enum TimerPhase { prep, response }
