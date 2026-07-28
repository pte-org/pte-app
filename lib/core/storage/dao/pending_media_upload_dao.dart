import 'package:drift/drift.dart';

import '../app_database.dart';
import '../pending_media_upload_status.dart';
import '../tables/pending_media_upload_table.dart';

part 'pending_media_upload_dao.g.dart';

@DriftAccessor(tables: [PendingMediaUploadTable])
class PendingMediaUploadDao extends DatabaseAccessor<AppDatabase> with _$PendingMediaUploadDaoMixin {
  PendingMediaUploadDao(super.db);

  /// Idempotent upsert on `(attemptPublicId, pinnedItemPublicId)` — a
  /// re-recorded task resets straight back to [PendingMediaUploadStatus.recorded]
  /// and clears any prior presign/error state, even over a row that had
  /// already progressed further.
  Future<void> upsertRecorded({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String localFilePath,
  }) {
    return into(pendingMediaUploadTable).insertOnConflictUpdate(
      PendingMediaUploadTableCompanion(
        attemptPublicId: Value(attemptPublicId),
        pinnedItemPublicId: Value(pinnedItemPublicId),
        localFilePath: Value(localFilePath),
        mediaPublicId: const Value(null),
        uploadUrl: const Value(null),
        uploadUrlExpiresAt: const Value(null),
        status: Value(PendingMediaUploadStatus.recorded.name),
        lastError: const Value(null),
      ),
    );
  }

  Future<PendingMediaUpload?> getRow(String attemptPublicId, String pinnedItemPublicId) {
    return (select(pendingMediaUploadTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.pinnedItemPublicId.equals(pinnedItemPublicId),
          ))
        .getSingleOrNull();
  }

  /// Reactive single-row query — the `READ_ALOUD` UI subscribes to this
  /// instead of polling, so it reflects the coordinator's background
  /// (canary/periodic) progress on this row without any manual refresh
  /// call.
  Stream<PendingMediaUpload?> watchRow(String attemptPublicId, String pinnedItemPublicId) {
    return (select(pendingMediaUploadTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.pinnedItemPublicId.equals(pinnedItemPublicId),
          ))
        .watchSingleOrNull();
  }

  /// Every row not yet [PendingMediaUploadStatus.ready] — the coordinator's
  /// scan set on every canary/periodic trigger.
  Future<List<PendingMediaUpload>> queryNonReady() {
    return (select(
      pendingMediaUploadTable,
    )..where((t) => t.status.equals(PendingMediaUploadStatus.ready.name).not())).get();
  }

  Future<void> markUploading(
    String attemptPublicId,
    String pinnedItemPublicId, {
    required String mediaPublicId,
    required String uploadUrl,
    required int uploadUrlExpiresAt,
  }) {
    return (update(pendingMediaUploadTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.pinnedItemPublicId.equals(pinnedItemPublicId),
          ))
        .write(
          PendingMediaUploadTableCompanion(
            mediaPublicId: Value(mediaPublicId),
            uploadUrl: Value(uploadUrl),
            uploadUrlExpiresAt: Value(uploadUrlExpiresAt),
            status: Value(PendingMediaUploadStatus.uploading.name),
          ),
        );
  }

  Future<void> markUploaded(String attemptPublicId, String pinnedItemPublicId) =>
      _updateStatus(attemptPublicId, pinnedItemPublicId, PendingMediaUploadStatus.uploaded);

  Future<void> markCompleting(String attemptPublicId, String pinnedItemPublicId) =>
      _updateStatus(attemptPublicId, pinnedItemPublicId, PendingMediaUploadStatus.completing);

  Future<void> markReady(String attemptPublicId, String pinnedItemPublicId) =>
      _updateStatus(attemptPublicId, pinnedItemPublicId, PendingMediaUploadStatus.ready);

  /// Records the failure for diagnostics without changing [status] — the
  /// row is retried from wherever it currently sits on the next
  /// canary/periodic trigger, mirroring `AnswerOutboxDao`'s
  /// leave-pending-on-transient-failure behavior (phase-06 Design
  /// Constraints: `complete` failures have no terminal-rejected
  /// equivalent, unbounded retry is correct here).
  Future<void> markError(String attemptPublicId, String pinnedItemPublicId, String error) {
    return (update(pendingMediaUploadTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.pinnedItemPublicId.equals(pinnedItemPublicId),
          ))
        .write(PendingMediaUploadTableCompanion(lastError: Value(error)));
  }

  Future<void> deleteRow(String attemptPublicId, String pinnedItemPublicId) {
    return (delete(pendingMediaUploadTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.pinnedItemPublicId.equals(pinnedItemPublicId),
          ))
        .go();
  }

  Future<void> _updateStatus(String attemptPublicId, String pinnedItemPublicId, PendingMediaUploadStatus status) {
    return (update(pendingMediaUploadTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.pinnedItemPublicId.equals(pinnedItemPublicId),
          ))
        .write(PendingMediaUploadTableCompanion(status: Value(status.name)));
  }
}
