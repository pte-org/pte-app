import 'package:drift/drift.dart';

import 'package:pte_app/core/security/lockdown_mode.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/tables/local_violations_table.dart';

part 'local_violation_dao.g.dart';

/// Offline queue of lockdown violations. Writes are offline-first
/// ([ViolationReporter] inserts the row before attempting HTTP), reads
/// power [ViolationReporter.retryUnsent]. Mirrors the offline-first
/// pattern already established by `AnswerOutboxDao` (Phase 2): row is
/// dropped from the unsent set only when the backend acknowledges the
/// POST.
@DriftAccessor(tables: [LocalViolationsTable])
class LocalViolationDao extends DatabaseAccessor<AppDatabase>
    with _$LocalViolationDaoMixin {
  LocalViolationDao(super.db);

  /// Persists a freshly-detected violation. Always returns the row id
  /// so callers can update `sent` in-place without a follow-up query.
  /// The id is required by [ViolationReporter]'s optimistic mark-sent
  /// step — re-fetching the row by composite key would be far more
  /// brittle than reading the autoincrement id out of the result.
  Future<int> insert(ViolationEvent event) {
    return into(localViolationsTable).insert(
      LocalViolationsTableCompanion(
        attemptPublicId: Value(event.attemptPublicId),
        violationType: Value(event.type.serverValue),
        severity: Value(event.severity.toServerValue()),
        timestamp: Value(event.timestamp),
        metadata: Value(event.metadata),
        sent: const Value(false),
      ),
    );
  }

  /// Every row whose `sent=false`, ordered by id so retry attempts
  /// are roughly in insertion order. Drift honors this ordering
  /// through its default `ORDER BY id ASC` only when explicitly
  /// requested — passing `(t) => OrderingTerm.asc(t.id)` is required
  /// because the DAO's existing `getUnsent` style is shared with
  /// `AnswerOutboxDao`, where order doesn't matter.
  Future<List<LocalViolation>> getUnsent() {
    return (select(localViolationsTable)
          ..where((t) => t.sent.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// Marks a specific row as acknowledged by the backend. Failure to
  /// flip this flag means the row will be retried on the next
  /// `retryUnsent` cycle (Phase 4 design constraint: never trust
  /// `sent=true` on a non-2xx response).
  Future<void> markSent(int id) {
    return (update(localViolationsTable)..where((t) => t.id.equals(id)))
        .write(const LocalViolationsTableCompanion(sent: Value(true)));
  }

  /// Bulk variant — preferred path for the retry loop, where the same
  /// call may flip many rows in one transaction.
  Future<void> markManySent(Iterable<int> ids) {
    if (ids.isEmpty) return Future.value();
    return (update(localViolationsTable)..where((t) => t.id.isIn(ids)))
        .write(const LocalViolationsTableCompanion(sent: Value(true)));
  }

  /// Removes rows that have been acknowledged AND are older than
  /// [olderThan]. Called on app start (and on a longer periodic timer
  /// inside the future proctor background task) to bound disk usage —
  /// the backend is the source of truth long-term, so the local copy
  /// is purely a retry buffer.
  Future<int> deleteOldSent({required Duration olderThan}) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(localViolationsTable)
          ..where(
            (t) => t.sent.equals(true) & t.timestamp.isSmallerThanValue(cutoff),
          ))
        .go();
  }

  /// Pulls every row for a given attempt — used by the manual
  /// `ExamHistoryScreen` debug view (Phase 5 owns the public-facing UI,
  /// this is internal tooling so it can stay simple).
  Future<List<LocalViolation>> getAllForAttempt(String attemptPublicId) {
    return (select(localViolationsTable)
          ..where((t) => t.attemptPublicId.equals(attemptPublicId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// Materializes a persisted row back into the in-memory event shape
  /// that [ViolationReporter] uses to build POST bodies. The
  /// `fromRow` round-trip exists so the retry loop never relies on
  /// the original `ViolationEvent` instance — by the time a retry
  /// happens, the original is long out of scope.
  static ViolationEvent fromRow(LocalViolation row) {
    return ViolationEvent(
      id: row.id,
      attemptPublicId: row.attemptPublicId,
      type: _safeType(row.violationType),
      severity: _safeSeverity(row.severity),
      timestamp: row.timestamp,
      metadata: row.metadata,
      sent: row.sent,
    );
  }

  static ViolationType _safeType(String value) {
    try {
      return ViolationType.fromServerValue(value);
    } on ArgumentError {
      // Server may have added new violation types in a future release —
      // fall back to the closest existing bucket instead of throwing,
      // so a single unknown type can't brick the retry queue.
      return ViolationType.shortcutBlocked;
    }
  }

  static ViolationSeverity _safeSeverity(String value) {
    final normalized = value.trim().toLowerCase();
    for (final sev in ViolationSeverity.values) {
      if (sev.name == normalized) return sev;
    }
    return ViolationSeverity.warning;
  }

  // Disambiguate the unused LockdownMode import — this DAO does not
  // declare a LockdownMode dependency directly, but the conversion
  // helpers above intentionally keep an unused import out of the file
  // surface so callers know the conversion is purely a row-shape
  // problem, not a mode-mapping one.
  static LockdownMode _unusedModeSeam() => LockdownMode.none;
}
