/// Sync status of a single buffered answer in the outbox. Stored as
/// `.name` (plain text) in [AnswerOutboxTable] (`tables/answer_outbox_table.dart`).
///
/// Diverges from the Phase 0 reference's `{pending, syncing, synced, failed}`
/// by splitting the single `failed` bucket into a transient-vs-terminal
/// distinction (phase-02 Design Constraints):
/// - [pending]: not yet synced, or a transient failure (network/5xx/429)
///   returned it here for the next flush pass to retry.
/// - [syncing]: reserved for a future concurrent-flush marker; not currently
///   set by [SyncEngine] (single-flight via `_isFlushing` makes it
///   unnecessary today), kept for shape-parity with the reference design.
/// - [synced]: the server accepted this answer.
/// - [terminalRejected]: a 409 response (stale task, expired response
///   window, or already-submitted) — never re-queried by the sync engine's
///   pending-query, a dead end for Milestone 1. A fresh local edit via
///   `upsertAnswer` resets a row back to [pending] even over this status.
enum AnswerSyncStatus { pending, syncing, synced, terminalRejected }
