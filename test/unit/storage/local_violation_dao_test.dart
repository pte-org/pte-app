import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/local_violation_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('insert / getUnsent / markSent', () {
    test('insert assigns an auto id, leaves sent=false, and lists under getUnsent', () async {
      final id = await db.localViolationDao.insert(
        const ViolationEvent(
          attemptPublicId: 'attempt-1',
          type: ViolationType.fullscreenExit,
          severity: ViolationSeverity.warning,
          timestamp: _t,
          metadata: '{}',
        ),
      );
      expect(id, isPositive);

      final unsent = await db.localViolationDao.getUnsent();
      expect(unsent, hasLength(1));
      expect(unsent.single.id, id);
      expect(unsent.single.sent, isFalse);
      expect(unsent.single.violationType, 'LOCKDOWN_FULLSCREEN_EXIT');
      expect(unsent.single.severity, 'WARNING');
    });

    test('markSent flips the row\'s sent flag and removes it from getUnsent', () async {
      final id = await db.localViolationDao.insert(
        const ViolationEvent(
          attemptPublicId: 'attempt-1',
          type: ViolationType.shortcutBlocked,
          severity: ViolationSeverity.critical,
          timestamp: _t,
        ),
      );
      await db.localViolationDao.markSent(id);
      expect((await db.localViolationDao.getUnsent()), isEmpty);
    });

    test('markManySent flips a contiguous range of ids in a single call', () async {
      final ids = <int>[];
      for (var i = 0; i < 3; i++) {
        ids.add(
          await db.localViolationDao.insert(
            ViolationEvent(
              attemptPublicId: 'attempt-$i',
              type: ViolationType.shortcutBlocked,
              severity: ViolationSeverity.warning,
              timestamp: _t,
            ),
          ),
        );
      }
      await db.localViolationDao.markManySent(ids.take(2));
      final unsent = await db.localViolationDao.getUnsent();
      expect(unsent.map((r) => r.id), [ids.last]);
    });
  });

  group('deleteOldSent', () {
    test('drops only rows with sent=true and timestamp older than the cutoff', () async {
      final oldId = await db.localViolationDao.insert(
        ViolationEvent(
          attemptPublicId: 'old',
          type: ViolationType.shortcutBlocked,
          severity: ViolationSeverity.warning,
          timestamp: DateTime.now().subtract(const Duration(days: 30)),
        ),
      );
      final freshId = await db.localViolationDao.insert(
        ViolationEvent(
          attemptPublicId: 'fresh',
          type: ViolationType.shortcutBlocked,
          severity: ViolationSeverity.warning,
          timestamp: DateTime.now(),
        ),
      );
      await db.localViolationDao.markSent(oldId);
      // freshId stays unsent

      final removed = await db.localViolationDao
          .deleteOldSent(olderThan: const Duration(days: 7));

      expect(removed, 1);
      final remainingIds = (await db.localViolationDao.getAllForAttempt('old')) +
          (await db.localViolationDao.getAllForAttempt('fresh'));
      expect(remainingIds.map((r) => r.id), [freshId]);
    });

    test('no-op when there are no rows past the cutoff', () async {
      final id = await db.localViolationDao.insert(
        ViolationEvent(
          attemptPublicId: 'fresh',
          type: ViolationType.shortcutBlocked,
          severity: ViolationSeverity.warning,
          timestamp: DateTime.now(),
        ),
      );
      await db.localViolationDao.markSent(id);

      final removed = await db.localViolationDao
          .deleteOldSent(olderThan: const Duration(days: 30));
      expect(removed, 0);
    });
  });

  group('getAllForAttempt', () {
    test('returns rows only for the matching attempt, ordered by id', () async {
      for (final attempt in ['a', 'a', 'b']) {
        await db.localViolationDao.insert(
          ViolationEvent(
            attemptPublicId: attempt,
            type: ViolationType.shortcutBlocked,
            severity: ViolationSeverity.warning,
            timestamp: _t,
          ),
        );
      }
      final rows = await db.localViolationDao.getAllForAttempt('a');
      expect(rows, hasLength(2));
      expect(rows.first.id, lessThan(rows.last.id));
    });
  });

  group('fromRow', () {
    test('round-trips an in-memory ViolationEvent through a Drift row', () async {
      final id = await db.localViolationDao.insert(
        const ViolationEvent(
          attemptPublicId: 'attempt-1',
          type: ViolationType.clipboardPaste,
          severity: ViolationSeverity.critical,
          timestamp: _t,
          metadata: '{"src":"clipboard"}',
        ),
      );
      final rows = await db.localViolationDao.getAllForAttempt('attempt-1');
      final restored = LocalViolationDao.fromRow(rows.single);

      expect(restored.id, id);
      expect(restored.attemptPublicId, 'attempt-1');
      expect(restored.type, ViolationType.clipboardPaste);
      expect(restored.severity, ViolationSeverity.critical);
      expect(restored.metadata, '{"src":"clipboard"}');
      expect(restored.sent, isFalse);
    });

    test('falls back to a safe type when the row carries an unknown serverValue', () async {
      // Simulates a future server-side enum addition the client hasn't
      // been updated for yet. The DAO must not throw on retry.
      final id = await db.localViolationDao.insert(
        const ViolationEvent(
          attemptPublicId: 'attempt-unknown',
          type: ViolationType.shortcutBlocked,
          severity: ViolationSeverity.warning,
          timestamp: _t,
        ),
      );
      await db.customStatement(
        'UPDATE local_violations SET violation_type = ? WHERE id = ?',
        ['FUTURE_TYPE', id],
      );

      final restored = LocalViolationDao.fromRow(
        (await db.localViolationDao.getAllForAttempt('attempt-unknown')).single,
      );
      expect(restored.type, ViolationType.shortcutBlocked);
    });
  });

  // LockdownMode import is referenced indirectly via ViolationEvent —
  // the future refactor that ties these together (Phase 5) will use
  // the import directly. Keep the reference so the analyzer doesn't
  // flag it as unused, but don't act on it now.
  LockdownMode _unusedSeam() => LockdownMode.none;
}

final DateTime _t = DateTime.utc(2026, 9, 9, 0, 0, 0);
