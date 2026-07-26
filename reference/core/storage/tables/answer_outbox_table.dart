import 'package:drift/drift.dart';

/// Local outbox of buffered student answers. Composite primary key
/// `(attemptId, questionId)` matches `aptis-be`'s SRS DC-05 upsert key,
/// so a repeated write for the same question is always an idempotent
/// update, never a duplicate row.
///
/// `createdAt`/`updatedAt` are audit-only — never read by timer/backoff
/// logic. Elapsed-time truth lives exclusively in `TimerService` (Phase 4).
@DataClassName('AnswerOutbox')
class AnswerOutboxTable extends Table {
  TextColumn get attemptId => text()();
  TextColumn get questionId => text()();
  TextColumn get content => text()();
  TextColumn get status => text()();
  TextColumn get lastSyncError => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {attemptId, questionId};
}
