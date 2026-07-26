import 'package:drift/drift.dart';

import '../drift_database.dart';
import '../models/answer_sync_status.dart';
import '../tables/answer_outbox_table.dart';

part 'answer_outbox_dao.g.dart';

@DriftAccessor(tables: [AnswerOutboxTable])
class AnswerOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$AnswerOutboxDaoMixin {
  AnswerOutboxDao(super.db);

  /// Idempotent upsert keyed on `(attemptId, questionId)` — a repeated
  /// write for the same question updates the existing row in place,
  /// it never creates a duplicate.
  Future<void> upsertAnswer({
    required String attemptId,
    required String questionId,
    required String content,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(answerOutboxTable).insertOnConflictUpdate(
      AnswerOutboxTableCompanion(
        attemptId: Value(attemptId),
        questionId: Value(questionId),
        content: Value(content),
        status: Value(AnswerSyncStatus.pending.name),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<AnswerOutbox>> queryByAttemptId(String attemptId) {
    return (select(
      answerOutboxTable,
    )..where((t) => t.attemptId.equals(attemptId))).get();
  }

  Future<List<AnswerOutbox>> queryPendingByAttemptId(String attemptId) {
    return (select(answerOutboxTable)..where(
          (t) =>
              t.attemptId.equals(attemptId) &
              t.status.equals(AnswerSyncStatus.pending.name),
        ))
        .get();
  }

  Future<void> markSynced(String attemptId, String questionId) {
    return _updateStatus(attemptId, questionId, AnswerSyncStatus.synced);
  }

  Future<void> markFailed(String attemptId, String questionId, String reason) {
    return (update(answerOutboxTable)..where(
          (t) =>
              t.attemptId.equals(attemptId) & t.questionId.equals(questionId),
        ))
        .write(
          AnswerOutboxTableCompanion(
            status: Value(AnswerSyncStatus.failed.name),
            lastSyncError: Value(reason),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> deleteByAttemptId(String attemptId) {
    return (delete(
      answerOutboxTable,
    )..where((t) => t.attemptId.equals(attemptId))).go();
  }

  /// Forces a WAL checkpoint. Call after a successful outbox-flush batch
  /// (Phase 5 sync engine) — under high-frequency answer writes, SQLite's
  /// default auto-checkpoint may not run often enough to bound WAL growth.
  Future<void> checkpointWal() {
    return customStatement('PRAGMA wal_checkpoint(RESTART);');
  }

  Future<void> _updateStatus(
    String attemptId,
    String questionId,
    AnswerSyncStatus status,
  ) {
    return (update(answerOutboxTable)..where(
          (t) =>
              t.attemptId.equals(attemptId) & t.questionId.equals(questionId),
        ))
        .write(
          AnswerOutboxTableCompanion(
            status: Value(status.name),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }
}
