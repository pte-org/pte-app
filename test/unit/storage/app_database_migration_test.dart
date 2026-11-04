import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:pte_app/core/storage/app_database.dart';

void main() {
  group('AppDatabase schema migrations', () {
    test('upgrade from schema v2 to v5 creates local violations and adds cloudinary columns', () async {
      final dir = await Directory.systemTemp.createTemp('pte_app_db_v2_migration');
      final dbFile = File(p.join(dir.path, 'test_v2.sqlite'));
      addTearDown(() async {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      // Prepare a v2 database
      final raw = sqlite3.sqlite3.open(dbFile.path);
      raw.execute('''
        CREATE TABLE answer_outbox_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          attempt_public_id TEXT NOT NULL,
          pinned_item_public_id TEXT NOT NULL,
          payload TEXT NOT NULL,
          status TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      raw.execute('''
        CREATE TABLE pending_media_upload_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          attempt_public_id TEXT NOT NULL,
          pinned_item_public_id TEXT NOT NULL,
          local_file_path TEXT NOT NULL,
          media_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          uploaded INTEGER NOT NULL DEFAULT 0,
          failed_attempts INTEGER NOT NULL DEFAULT 0,
          last_failure_reason TEXT
        );
      ''');
      raw.execute('PRAGMA user_version = 2;');
      raw.close();

      // Open through AppDatabase which triggers onUpgrade(from: 2, to: 5)
      final appDb = AppDatabase(NativeDatabase(dbFile));
      // Force connection open and migration to execute
      await appDb.customSelect('SELECT 1').get();

      // Verify local_violations_table was created (from < 3)
      final violationRows = await appDb.customSelect('SELECT * FROM local_violations_table').get();
      expect(violationRows, isEmpty);

      // Verify Cloudinary columns were added to pending_media_upload_table (from < 4)
      final tableInfo = await appDb.customSelect("PRAGMA table_info('pending_media_upload_table')").get();
      final columnNames = tableInfo.map((row) => row.data['name'] as String).toSet();
      expect(columnNames, contains('cloudinary_api_key'));
      expect(columnNames, contains('cloudinary_timestamp'));
      expect(columnNames, contains('cloudinary_upload_signature'));
      expect(columnNames, contains('cloudinary_folder'));
      expect(columnNames, contains('cloudinary_resource_type'));
      expect(columnNames, contains('cloudinary_public_id'));
      expect(columnNames, contains('cloudinary_asset_id'));
      expect(columnNames, contains('cloudinary_secure_url'));
      expect(columnNames, contains('cloudinary_format'));
      expect(columnNames, contains('cloudinary_bytes'));
      expect(columnNames, contains('cloudinary_duration_seconds'));
      expect(columnNames, contains('cloudinary_version'));
      expect(columnNames, contains('cloudinary_signature'));

      await appDb.close();
    });

    test('upgrade from schema v3 to v5 migrates local violations table and cloudinary columns', () async {
      final dir = await Directory.systemTemp.createTemp('pte_app_db_v3_migration');
      final dbFile = File(p.join(dir.path, 'test_v3.sqlite'));
      addTearDown(() async {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      // Prepare a v3 database
      final raw = sqlite3.sqlite3.open(dbFile.path);
      raw.execute('''
        CREATE TABLE answer_outbox_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          attempt_public_id TEXT NOT NULL,
          pinned_item_public_id TEXT NOT NULL,
          payload TEXT NOT NULL,
          status TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      raw.execute('''
        CREATE TABLE pending_media_upload_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          attempt_public_id TEXT NOT NULL,
          pinned_item_public_id TEXT NOT NULL,
          local_file_path TEXT NOT NULL,
          media_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          uploaded INTEGER NOT NULL DEFAULT 0,
          failed_attempts INTEGER NOT NULL DEFAULT 0,
          last_failure_reason TEXT
        );
      ''');
      raw.execute('''
        CREATE TABLE local_violations_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          attempt_public_id TEXT NOT NULL,
          violation_type TEXT NOT NULL,
          severity TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          metadata TEXT,
          sent INTEGER NOT NULL DEFAULT 0
        );
      ''');
      raw.execute(
        'INSERT INTO local_violations_table '
        '(attempt_public_id, violation_type, severity, timestamp, metadata, sent) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [
          'att-v3-upgrade',
          'LOCKDOWN_FULLSCREEN_EXIT',
          'WARNING',
          DateTime.utc(2026, 11, 4).millisecondsSinceEpoch,
          null,
          0,
        ],
      );
      raw.execute('PRAGMA user_version = 3;');
      raw.close();

      // Open with AppDatabase (triggers onUpgrade from 3 to 5)
      final appDb = AppDatabase(NativeDatabase(dbFile));
      final rows = await appDb.localViolationDao.getAllForAttempt('att-v3-upgrade');

      expect(rows, hasLength(1));
      expect(rows.single.clientEventId, isNotEmpty);
      expect(rows.single.terminal, isFalse);

      await appDb.close();
    });
  });
}

