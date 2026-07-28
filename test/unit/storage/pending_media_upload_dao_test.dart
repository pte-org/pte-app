import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/pending_media_upload_status.dart';

void main() {
  group('PendingMediaUploadDao — in-memory CRUD/transition behavior', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('upsertRecorded is idempotent and resets a further-progressed row back to recorded', () async {
      await db.pendingMediaUploadDao.upsertRecorded(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        localFilePath: '/tmp/a1_p1.wav',
      );
      await db.pendingMediaUploadDao.markUploading(
        'a1',
        'p1',
        mediaPublicId: 'media-1',
        uploadUrl: 'https://minio/x',
        uploadUrlExpiresAt: 123,
      );

      var row = await db.pendingMediaUploadDao.getRow('a1', 'p1');
      expect(row!.status, PendingMediaUploadStatus.uploading.name);

      // A re-recorded task resets straight back to `recorded`, clearing any
      // prior presign state, even though the row had already progressed.
      await db.pendingMediaUploadDao.upsertRecorded(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        localFilePath: '/tmp/a1_p1_v2.wav',
      );

      row = await db.pendingMediaUploadDao.getRow('a1', 'p1');
      expect(row!.status, PendingMediaUploadStatus.recorded.name);
      expect(row.localFilePath, '/tmp/a1_p1_v2.wav');
      expect(row.mediaPublicId, isNull);
      expect(row.uploadUrl, isNull);
      expect(row.uploadUrlExpiresAt, isNull);
    });

    test('queryNonReady returns every row not at ready, never a ready one', () async {
      await db.pendingMediaUploadDao.upsertRecorded(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'recorded-1',
        localFilePath: '/tmp/x.wav',
      );
      await db.pendingMediaUploadDao.upsertRecorded(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'ready-1',
        localFilePath: '/tmp/y.wav',
      );
      await db.pendingMediaUploadDao.markUploading(
        'a1',
        'ready-1',
        mediaPublicId: 'media-1',
        uploadUrl: 'https://minio/y',
        uploadUrlExpiresAt: 123,
      );
      await db.pendingMediaUploadDao.markUploaded('a1', 'ready-1');
      await db.pendingMediaUploadDao.markCompleting('a1', 'ready-1');
      await db.pendingMediaUploadDao.markReady('a1', 'ready-1');

      final nonReady = await db.pendingMediaUploadDao.queryNonReady();

      expect(nonReady.map((r) => r.pinnedItemPublicId), ['recorded-1']);
    });

    test('watchRow emits the current row on every status transition, reactively', () async {
      await db.pendingMediaUploadDao.upsertRecorded(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        localFilePath: '/tmp/x.wav',
      );

      final statuses = <String?>[];
      final sub = db.pendingMediaUploadDao.watchRow('a1', 'p1').listen((row) => statuses.add(row?.status));

      await pumpEventQueue();
      await db.pendingMediaUploadDao.markUploading(
        'a1',
        'p1',
        mediaPublicId: 'media-1',
        uploadUrl: 'https://minio/x',
        uploadUrlExpiresAt: 123,
      );
      await pumpEventQueue();
      await db.pendingMediaUploadDao.deleteRow('a1', 'p1');
      await pumpEventQueue();

      expect(statuses, [
        PendingMediaUploadStatus.recorded.name,
        PendingMediaUploadStatus.uploading.name,
        null,
      ]);

      await sub.cancel();
    });

    test('markError records the failure without changing status — row is retried from wherever it sits', () async {
      await db.pendingMediaUploadDao.upsertRecorded(
        attemptPublicId: 'a1',
        pinnedItemPublicId: 'p1',
        localFilePath: '/tmp/x.wav',
      );

      await db.pendingMediaUploadDao.markError('a1', 'p1', 'network blip');

      final row = await db.pendingMediaUploadDao.getRow('a1', 'p1');
      expect(row!.status, PendingMediaUploadStatus.recorded.name);
      expect(row.lastError, 'network blip');
    });
  });

  test(
    'process-death simulation (Step 11): a row persisted at `uploaded` via the real DAO survives destroying and '
    'reconstructing the database instance from the same file, unchanged',
    () async {
      final dir = await Directory.systemTemp.createTemp('pte_app_media_dao_test');
      final dbFile = File(p.join(dir.path, 'test.sqlite'));
      addTearDown(() async {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      final firstInstance = AppDatabase(NativeDatabase(dbFile));
      await firstInstance.pendingMediaUploadDao.upsertRecorded(
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        localFilePath: '/tmp/attempt-1_item-1.wav',
      );
      await firstInstance.pendingMediaUploadDao.markUploading(
        'attempt-1',
        'item-1',
        mediaPublicId: 'media-public-id-1',
        uploadUrl: 'https://minio.example.com/bucket/object?sig=abc',
        uploadUrlExpiresAt: 1234567890,
      );
      await firstInstance.pendingMediaUploadDao.markUploaded('attempt-1', 'item-1');
      await firstInstance.close();

      final secondInstance = AppDatabase(NativeDatabase(dbFile));
      final row = await secondInstance.pendingMediaUploadDao.getRow('attempt-1', 'item-1');
      await secondInstance.close();

      expect(row, isNotNull);
      expect(row!.status, PendingMediaUploadStatus.uploaded.name);
      expect(row.mediaPublicId, 'media-public-id-1');
      expect(row.localFilePath, '/tmp/attempt-1_item-1.wav');
    },
  );
}
