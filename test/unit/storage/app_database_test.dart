import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:pte_app/core/storage/answer_sync_status.dart';
import 'package:pte_app/core/storage/app_database.dart';

void main() {
  test(
    'a real file-backed outbox row survives destroying and reconstructing the database instance '
    '(process-death survival, the core reliability property of this phase)',
    () async {
      final dir = await Directory.systemTemp.createTemp('pte_app_db_test');
      final dbFile = File(p.join(dir.path, 'test.sqlite'));
      addTearDown(() async {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      final firstInstance = AppDatabase(NativeDatabase(dbFile));
      await firstInstance.answerOutboxDao.upsertAnswer(
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        payload: 'survives restart',
      );
      await firstInstance.close();

      final secondInstance = AppDatabase(NativeDatabase(dbFile));
      final rows = await secondInstance.answerOutboxDao.queryByAttempt(
        'attempt-1',
      );
      await secondInstance.close();

      expect(rows, hasLength(1));
      expect(rows.single.payload, 'survives restart');
      expect(rows.single.status, AnswerSyncStatus.pending.name);
    },
  );

  test(
    'schema v4 lockdown rows receive a unique client event id on upgrade',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'pte_app_db_migration_test',
      );
      final dbFile = File(p.join(dir.path, 'test.sqlite'));
      addTearDown(() async {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      final initial = AppDatabase(NativeDatabase(dbFile));
      // Force the LazyDatabase to open and create the current schema before
      // replacing the violation table with the legacy v4 shape.
      await initial.customSelect('SELECT 1').get();
      await initial.close();

      final raw = sqlite3.sqlite3.open(dbFile.path);
      raw.execute('DROP TABLE local_violations_table');
      raw.execute('''
      CREATE TABLE local_violations_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_public_id TEXT NOT NULL,
        violation_type TEXT NOT NULL,
        severity TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        metadata TEXT,
        sent INTEGER NOT NULL DEFAULT 0
      )
    ''');
      raw.execute(
        'INSERT INTO local_violations_table '
        '(attempt_public_id, violation_type, severity, timestamp, metadata, sent) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [
          'attempt-legacy',
          'LOCKDOWN_FULLSCREEN_EXIT',
          'WARNING',
          DateTime.utc(2026, 9, 28).millisecondsSinceEpoch,
          null,
          0,
        ],
      );
      raw.execute('PRAGMA user_version = 4');
      raw.close();

      final migrated = AppDatabase(NativeDatabase(dbFile));
      final rows = await migrated.localViolationDao.getAllForAttempt(
        'attempt-legacy',
      );
      await migrated.close();

      expect(rows, hasLength(1));
      expect(rows.single.clientEventId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(rows.single.terminal, isFalse);
    },
  );
}
