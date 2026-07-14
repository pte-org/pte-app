/// Sync status of a single buffered answer in the outbox.
///
/// Stored as `.name` (plain text) in the Drift table — see
/// [AnswerOutboxTable] in `../tables/answer_outbox_table.dart`.
enum AnswerSyncStatus { pending, syncing, synced, failed }
