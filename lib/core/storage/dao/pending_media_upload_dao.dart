import 'package:drift/drift.dart';

import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/network/cloudinary_upload_result.dart';
import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/core/storage/tables/pending_media_upload_table.dart';

part 'pending_media_upload_dao.g.dart';

@DriftAccessor(tables: [PendingMediaUploadTable])
class PendingMediaUploadDao extends DatabaseAccessor<AppDatabase>
    with _$PendingMediaUploadDaoMixin {
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
        cloudinaryApiKey: const Value(null),
        cloudinaryTimestamp: const Value(null),
        cloudinaryUploadSignature: const Value(null),
        cloudinaryFolder: const Value(null),
        cloudinaryResourceType: const Value(null),
        cloudinaryPublicId: const Value(null),
        cloudinaryAssetId: const Value(null),
        cloudinarySecureUrl: const Value(null),
        cloudinaryFormat: const Value(null),
        cloudinaryBytes: const Value(null),
        cloudinaryDurationSeconds: const Value(null),
        cloudinaryVersion: const Value(null),
        cloudinarySignature: const Value(null),
        status: Value(PendingMediaUploadStatus.recorded.name),
        lastError: const Value(null),
      ),
    );
  }

  Future<PendingMediaUpload?> getRow(
    String attemptPublicId,
    String pinnedItemPublicId,
  ) {
    return (select(pendingMediaUploadTable)..where(
          (t) =>
              t.attemptPublicId.equals(attemptPublicId) &
              t.pinnedItemPublicId.equals(pinnedItemPublicId),
        ))
        .getSingleOrNull();
  }

  /// Reactive single-row query — the `READ_ALOUD` UI subscribes to this
  /// instead of polling, so it reflects the coordinator's background
  /// (canary/periodic) progress on this row without any manual refresh
  /// call.
  Stream<PendingMediaUpload?> watchRow(
    String attemptPublicId,
    String pinnedItemPublicId,
  ) {
    return (select(pendingMediaUploadTable)..where(
          (t) =>
              t.attemptPublicId.equals(attemptPublicId) &
              t.pinnedItemPublicId.equals(pinnedItemPublicId),
        ))
        .watchSingleOrNull();
  }

  /// Every row not yet [PendingMediaUploadStatus.ready] — the coordinator's
  /// scan set on every canary/periodic trigger.
  Future<List<PendingMediaUpload>> queryNonReady() {
    return (select(pendingMediaUploadTable)..where(
          (t) => t.status.equals(PendingMediaUploadStatus.ready.name).not(),
        ))
        .get();
  }

  Future<void> markUploading(
    String attemptPublicId,
    String pinnedItemPublicId, {
    required String mediaPublicId,
    required String uploadUrl,
    required int uploadUrlExpiresAt,
    String apiKey = '',
    String timestamp = '',
    String signature = '',
    String folder = '',
    String resourceType = 'video',
    String publicId = '',
  }) {
    return (update(pendingMediaUploadTable)..where(
          (t) =>
              t.attemptPublicId.equals(attemptPublicId) &
              t.pinnedItemPublicId.equals(pinnedItemPublicId),
        ))
        .write(
          PendingMediaUploadTableCompanion(
            mediaPublicId: Value(mediaPublicId),
            uploadUrl: Value(uploadUrl),
            uploadUrlExpiresAt: Value(uploadUrlExpiresAt),
            cloudinaryApiKey: Value(apiKey),
            cloudinaryTimestamp: Value(timestamp),
            cloudinaryUploadSignature: Value(signature),
            cloudinaryFolder: Value(folder),
            cloudinaryResourceType: Value(resourceType),
            cloudinaryPublicId: Value(publicId),
            status: Value(PendingMediaUploadStatus.uploading.name),
          ),
        );
  }

  Future<void> markUploaded(
    String attemptPublicId,
    String pinnedItemPublicId, {
    CloudinaryUploadResult? result,
  }) {
    if (result == null) {
      return _updateStatus(
        attemptPublicId,
        pinnedItemPublicId,
        PendingMediaUploadStatus.uploaded,
      );
    }
    return (update(pendingMediaUploadTable)..where(
          (t) =>
              t.attemptPublicId.equals(attemptPublicId) &
              t.pinnedItemPublicId.equals(pinnedItemPublicId),
        ))
        .write(
          PendingMediaUploadTableCompanion(
            cloudinaryPublicId: Value(result.publicId),
            cloudinaryAssetId: Value(result.assetId),
            cloudinarySecureUrl: Value(result.secureUrl),
            cloudinaryResourceType: Value(result.resourceType),
            cloudinaryFormat: Value(result.format),
            cloudinaryBytes: Value(result.bytes),
            cloudinaryDurationSeconds: Value(result.durationSeconds),
            cloudinaryVersion: Value(result.version),
            cloudinarySignature: Value(result.signature),
            status: Value(PendingMediaUploadStatus.uploaded.name),
          ),
        );
  }

  Future<void> markCompleting(
    String attemptPublicId,
    String pinnedItemPublicId,
  ) => _updateStatus(
    attemptPublicId,
    pinnedItemPublicId,
    PendingMediaUploadStatus.completing,
  );

  Future<void> markReady(String attemptPublicId, String pinnedItemPublicId) =>
      _updateStatus(
        attemptPublicId,
        pinnedItemPublicId,
        PendingMediaUploadStatus.ready,
      );

  /// Records the failure for diagnostics without changing [status] — the
  /// row is retried from wherever it currently sits on the next
  /// canary/periodic trigger, mirroring `AnswerOutboxDao`'s
  /// leave-pending-on-transient-failure behavior (phase-06 Design
  /// Constraints: `complete` failures have no terminal-rejected
  /// equivalent, unbounded retry is correct here).
  Future<void> markError(
    String attemptPublicId,
    String pinnedItemPublicId,
    String error,
  ) {
    return (update(pendingMediaUploadTable)..where(
          (t) =>
              t.attemptPublicId.equals(attemptPublicId) &
              t.pinnedItemPublicId.equals(pinnedItemPublicId),
        ))
        .write(PendingMediaUploadTableCompanion(lastError: Value(error)));
  }

  Future<void> deleteRow(String attemptPublicId, String pinnedItemPublicId) {
    return (delete(pendingMediaUploadTable)..where(
          (t) =>
              t.attemptPublicId.equals(attemptPublicId) &
              t.pinnedItemPublicId.equals(pinnedItemPublicId),
        ))
        .go();
  }

  Future<void> _updateStatus(
    String attemptPublicId,
    String pinnedItemPublicId,
    PendingMediaUploadStatus status,
  ) {
    return (update(pendingMediaUploadTable)..where(
          (t) =>
              t.attemptPublicId.equals(attemptPublicId) &
              t.pinnedItemPublicId.equals(pinnedItemPublicId),
        ))
        .write(PendingMediaUploadTableCompanion(status: Value(status.name)));
  }
}
