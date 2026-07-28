/// Progress of one `READ_ALOUD` recording through the media pipeline.
/// Stored as `.name` (plain text) in [PendingMediaUploadTable]
/// (`tables/pending_media_upload_table.dart`). A separate track from
/// [AnswerSyncStatus] (Phase 2) — the outbox never sees a row until it
/// reaches [ready] (phase-06 Design Constraints).
///
/// - [recorded]: local file captured, no presign requested yet.
/// - [uploading]: presigned (`mediaPublicId`/`uploadUrl` set), `PUT` not
///   yet confirmed.
/// - [uploaded]: `PUT` succeeded, `complete` not yet called.
/// - [completing]: `complete` call in flight or previously failed —
///   retried from here, never by re-uploading.
/// - [ready]: `complete` succeeded. The coordinator hands this row to
///   `AnswerOutboxDao.upsertAnswer` and removes the row.
enum PendingMediaUploadStatus { recorded, uploading, uploaded, completing, ready }
