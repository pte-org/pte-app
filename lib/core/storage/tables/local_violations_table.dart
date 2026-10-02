import 'package:drift/drift.dart';

/// Offline queue of lockdown violations awaiting acknowledgement from the
/// authenticated student-attempt endpoint. One row per detected event,
/// flagged `sent=true` only after the server accepts the idempotent receipt.
/// Local severity is retained for diagnostics; it is not a client authority
/// field in the outbound payload. The schema
/// deliberately mirrors the persisted audit row rather than the outbound
/// request body.
/// The transport adapter owns the request projection.
@DataClassName('LocalViolation')
class LocalViolationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable client-generated idempotency key. The empty SQL default exists so
  /// SQLite can add this non-null column to an existing table; the migration
  /// immediately backfills every old row and the DAO supplies the real value
  /// for new rows. A unique index is created by AppDatabase after creation or
  /// backfill because SQLite cannot add a UNIQUE column constraint with ALTER.
  TextColumn get clientEventId => text().withDefault(const Constant(''))();

  /// `attempt_public_id` — same opaque id as everywhere else (e.g.
  /// `AnswerOutboxTable.attemptPublicId`). It is carried in the request URL,
  /// not duplicated in the request body.
  TextColumn get attemptPublicId => text()();

  /// Wire string for `ViolationType` (e.g. `LOCKDOWN_FULLSCREEN_EXIT`).
  /// Stored as plain text rather than an enum index so adding a new
  /// violation type to the backend doesn't force a database migration.
  TextColumn get violationType => text()();

  /// `WARNING` / `CRITICAL` for local diagnostics only.
  TextColumn get severity => text()();

  DateTimeColumn get timestamp => dateTime()();

  /// Free-form JSON envelope for additional context. Nullable for
  /// violation types that have no extra context (`screenshot attempt`
  /// doesn't need anything beyond the fact it happened).
  TextColumn get metadata => text().nullable()();

  /// Sync flag. `false` until the violation has been acknowledged by
  /// the backend.
  BoolColumn get sent => boolean().withDefault(const Constant(false))();

  /// A policy or type rejection is terminal for this row. Keep the row and
  /// reason for diagnostics, but do not retry it forever.
  BoolColumn get terminal => boolean().withDefault(const Constant(false))();

  TextColumn get terminalReason => text().nullable()();
}
