import 'package:drift/drift.dart';

/// Offline queue of lockdown violations awaiting acknowledgement from the
/// proctor backend. One row per detected event, flagged `sent=true` only
/// after `POST /api/proctor/violations` returns success. The schema
/// deliberately mirrors what proctor's `violation_events` table already
/// accepts (Phase 1's enum additions are the only change the server
/// needs), so the upstream POST body is a direct projection from this
/// row's columns — keeping the client payload identical to past phases
/// meant the backend never had to grow a new endpoint to satisfy
/// lockdown.
@DataClassName('LocalViolation')
class LocalViolationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `attempt_public_id` — same opaque id as everywhere else (e.g.
  /// `AnswerOutboxTable.attemptPublicId`); the proctor endpoint already
  /// understands this id and uses it to attribute violations to the
  /// session tab on the proctor dashboard.
  TextColumn get attemptPublicId => text()();

  /// Wire string for `ViolationType` (e.g. `LOCKDOWN_FULLSCREEN_EXIT`).
  /// Stored as plain text rather than an enum index so adding a new
  /// violation type to the backend doesn't force a database migration.
  TextColumn get violationType => text()();

  /// `WARNING` / `CRITICAL` — same casing the proctor endpoint accepts.
  TextColumn get severity => text()();

  DateTimeColumn get timestamp => dateTime()();

  /// Free-form JSON envelope for additional context. Nullable for
  /// violation types that have no extra context (`screenshot attempt`
  /// doesn't need anything beyond the fact it happened).
  TextColumn get metadata => text().nullable()();

  /// Sync flag. `false` until the violation has been acknowledged by
  /// the backend.
  BoolColumn get sent => boolean().withDefault(const Constant(false))();
}
