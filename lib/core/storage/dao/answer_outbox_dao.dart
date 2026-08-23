import 'package:drift/drift.dart';

import 'package:pte_app/core/storage/answer_sync_status.dart';
import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/tables/answer_outbox_table.dart';

part 'answer_outbox_dao.g.dart';

@DriftAccessor(tables: [AnswerOutboxTable])
class AnswerOutboxDao extends DatabaseAccessor<AppDatabase> with _$AnswerOutboxDaoMixin {
  AnswerOutboxDao(super.db);

  /// Idempotent upsert keyed on `(attemptPublicId, pinnedItemPublicId)`.
  /// Always resets `status` to [AnswerSyncStatus.pending] — even over a
  /// [AnswerSyncStatus.terminalRejected] row — since a fresh local edit to
  /// what the student believes is still an open task deserves one honest
  /// attempt, not a silent drop because a *previous* payload for that same
  /// key was rejected (phase-02 Design Constraints).
  Future<void> upsertAnswer({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String payload,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(answerOutboxTable).insertOnConflictUpdate(
      AnswerOutboxTableCompanion(
        attemptPublicId: Value(attemptPublicId),
        pinnedItemPublicId: Value(pinnedItemPublicId),
        payload: Value(payload),
        status: Value(AnswerSyncStatus.pending.name),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// All rows for an attempt, any status — needed by Phase 3's resume
  /// reconciliation.
  Future<List<AnswerOutbox>> queryByAttempt(String attemptPublicId) {
    return (select(answerOutboxTable)..where((t) => t.attemptPublicId.equals(attemptPublicId))).get();
  }

  Future<List<AnswerOutbox>> queryPendingByAttempt(String attemptPublicId) {
    return (select(answerOutboxTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.status.equals(AnswerSyncStatus.pending.name),
          ))
        .get();
  }

  /// A single row by its composite key, or `null` if none exists. Used by
  /// `SyncEngine.flushOne` to target exactly the requested task without a
  /// full per-attempt fetch.
  Future<AnswerOutbox?> getAnswer(String attemptPublicId, String pinnedItemPublicId) {
    return (select(answerOutboxTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.pinnedItemPublicId.equals(pinnedItemPublicId),
          ))
        .getSingleOrNull();
  }

  Future<void> markSynced(String attemptPublicId, String pinnedItemPublicId) =>
      _updateStatus(attemptPublicId, pinnedItemPublicId, AnswerSyncStatus.synced);

  /// Returns a row to retry-pending after a transient failure.
  Future<void> markPending(String attemptPublicId, String pinnedItemPublicId) =>
      _updateStatus(attemptPublicId, pinnedItemPublicId, AnswerSyncStatus.pending);

  Future<void> markTerminalRejected(String attemptPublicId, String pinnedItemPublicId, String reason) =>
      _updateStatus(attemptPublicId, pinnedItemPublicId, AnswerSyncStatus.terminalRejected, lastSyncError: reason);

  Future<void> deleteByAttempt(String attemptPublicId) {
    return (delete(answerOutboxTable)..where((t) => t.attemptPublicId.equals(attemptPublicId))).go();
  }

  /// Forces a WAL checkpoint. Called after each flush batch — under
  /// high-frequency answer writes, SQLite's default auto-checkpoint may not
  /// run often enough to bound WAL growth.
  Future<void> checkpointWal() {
    return customStatement('PRAGMA wal_checkpoint(RESTART);');
  }

  Future<void> _updateStatus(
    String attemptPublicId,
    String pinnedItemPublicId,
    AnswerSyncStatus status, {
    String? lastSyncError,
  }) {
    return (update(answerOutboxTable)
          ..where(
            (t) => t.attemptPublicId.equals(attemptPublicId) & t.pinnedItemPublicId.equals(pinnedItemPublicId),
          ))
        .write(
          AnswerOutboxTableCompanion(
            status: Value(status.name),
            lastSyncError: lastSyncError == null ? const Value.absent() : Value(lastSyncError),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }
}
