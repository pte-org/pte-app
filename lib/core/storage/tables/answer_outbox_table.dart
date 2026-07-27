import 'package:drift/drift.dart';

/// Local outbox of buffered student answers. Composite primary key
/// `(attemptPublicId, pinnedItemPublicId)` — a repeated write for the same
/// task is always an idempotent update, never a duplicate row.
///
/// `payload` is stored opaque: this table never parses, validates, or
/// type-branches on it — that is each task-type call site's own concern
/// (phase-02 Design Constraints).
///
/// `createdAt`/`updatedAt` are audit-only — never read by retry/backoff
/// logic. Elapsed-time truth lives exclusively in `TimerService` (Phase 4).
@DataClassName('AnswerOutbox')
class AnswerOutboxTable extends Table {
  TextColumn get attemptPublicId => text()();
  TextColumn get pinnedItemPublicId => text()();
  TextColumn get payload => text()();
  TextColumn get status => text()();
  TextColumn get lastSyncError => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {attemptPublicId, pinnedItemPublicId};
}
