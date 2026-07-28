import 'package:drift/drift.dart';

/// Tracks one `READ_ALOUD` recording through the presign → upload →
/// complete pipeline. Composite primary key `(attemptPublicId,
/// pinnedItemPublicId)` — same idempotent-upsert reason as
/// `AnswerOutboxTable` (Phase 2). A separate table from the answer outbox
/// on purpose: `AnswerOutboxTable`/`SyncEngine` must never be taught about
/// presigned URLs, upload progress, or re-presign logic (phase-06 Design
/// Constraints).
@DataClassName('PendingMediaUpload')
class PendingMediaUploadTable extends Table {
  TextColumn get attemptPublicId => text()();
  TextColumn get pinnedItemPublicId => text()();

  /// Local temp-file path the recording was written to — never held only
  /// in memory, so a deferred/retried upload survives process death.
  TextColumn get localFilePath => text()();

  /// Nullable until the first successful presign.
  TextColumn get mediaPublicId => text().nullable()();

  /// Nullable, re-set on every (re-)presign.
  TextColumn get uploadUrl => text().nullable()();

  /// Epoch ms, nullable, re-set on every (re-)presign.
  IntColumn get uploadUrlExpiresAt => integer().nullable()();

  TextColumn get status => text()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {attemptPublicId, pinnedItemPublicId};
}
