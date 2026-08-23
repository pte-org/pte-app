import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/media_repository.dart';
import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/network/raw_upload_client.dart';
import 'package:pte_app/core/storage/answer_sync_status.dart';
import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_single_cubit.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockMediaRepository extends Mock implements MediaRepository {}

class _MockRawUploadClient extends Mock implements RawUploadClient {}

class _FakeCanary implements NetworkCanary {
  @override
  Stream<void> get available => const Stream<void>.empty();

  @override
  Future<void> dispose() async {}
}

Response<void> _okResponse() => Response<void>(requestOptions: RequestOptions(path: '/x'), statusCode: 200);

/// This phase's centerpiece verification (phase-07 Steps 6-7, Design
/// Constraints, Risks): a genuinely OS-level "kill -9 the process, relaunch,
/// confirm the answer survives" cannot be triggered from this test harness —
/// there is no `integration_test`/device-automation dependency in this
/// project, and true process-kill automation has well-known platform
/// limitations even where that package is available (see this phase's
/// Risks). The achievable, still-meaningful proxy exercised here — matching
/// the same approach Phase 6 already established for its own process-death
/// simulation (`pending_media_upload_dao_test.dart`) — is: write through the
/// real UI-facing Cubit into a **real, file-backed** Drift database, destroy
/// that `AppDatabase` instance entirely (dropping every in-memory
/// object/stream), then reconstruct a brand-new `AppDatabase` (and every
/// service built on top of it) from the *same file path*, and confirm the
/// answer is not just present but still flushes correctly afterward. This
/// proves the SQLite write actually reached disk and that a freshly
/// reconstructed service graph resumes it correctly — the two properties
/// that matter, short of a literal OS-level kill.
void main() {
  late Directory tempDir;
  late String dbPath;

  setUpAll(() {
    registerFallbackValue(File(''));
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pte_app_kill_recovery_test');
    dbPath = p.join(tempDir.path, 'recovery_test.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
    'text-payload path (Step 6): an MC_READING_SINGLE selection survives destroying and reconstructing the '
    'database instance, then flushes exactly once via a freshly-built SyncEngine',
    () async {
      const attemptPublicId = 'attempt-1';
      const pinnedItemPublicId = 'item-1';

      // "Answer a task" through the real UI-facing Cubit, against a
      // real file-backed database — not an in-memory one, since the point
      // is proving the write survives losing every in-memory object.
      final firstDb = AppDatabase(NativeDatabase(File(dbPath)));
      final cubit = McReadingSingleCubit(
        outboxDao: firstDb.answerOutboxDao,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: pinnedItemPublicId,
      );
      await cubit.selectOption('2');
      await cubit.close();

      // "Kill": drop every in-memory object tied to the first instance,
      // including the database connection itself.
      await firstDb.close();

      // "Cold relaunch": a brand-new AppDatabase from the same file, with
      // no continuity from the instance above whatsoever.
      final secondDb = AppDatabase(NativeDatabase(File(dbPath)));
      addTearDown(secondDb.close);

      final recovered = await secondDb.answerOutboxDao.getAnswer(attemptPublicId, pinnedItemPublicId);
      expect(recovered, isNotNull, reason: 'the selection must have reached disk before "kill", not just memory');
      expect(recovered!.status, AnswerSyncStatus.pending.name);
      expect(recovered.payload, '2');

      // Confirm it's not just present but actually still flushes correctly
      // from a freshly-built SyncEngine — the "and eventually flushes" half
      // of this phase's Success Criteria, not just "the row exists".
      final apiClient = _MockApiClient();
      when(
        () => apiClient.submitAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => _okResponse());

      final syncEngine = SyncEngine(outboxDao: secondDb.answerOutboxDao, apiClient: apiClient, canary: _FakeCanary());
      syncEngine.startSync(attemptPublicId);
      await syncEngine.flushNow(attemptPublicId);
      syncEngine.stopSync();

      verify(
        () => apiClient.submitAnswer(attemptPublicId: attemptPublicId, pinnedItemPublicId: pinnedItemPublicId, payload: '2'),
      ).called(1);
      final synced = await secondDb.answerOutboxDao.getAnswer(attemptPublicId, pinnedItemPublicId);
      expect(synced!.status, AnswerSyncStatus.synced.name);
    },
  );

  test(
    'media-upload path (Step 7): a READ_ALOUD recording persisted at `uploaded` (upload succeeded, complete not '
    'yet called) survives destroying and reconstructing the database instance, then resumes at completing/ready '
    'via a freshly-built MediaUploadCoordinator — never re-uploading',
    () async {
      const attemptPublicId = 'attempt-1';
      const pinnedItemPublicId = 'item-read-aloud';

      // Simulate "recording done, upload succeeded, kill happens before
      // complete is called" — the exact scenario phase-06's own Step 11 unit
      // test covers with a fake DAO; this is the full-stack version through
      // the real coordinator, real DB file, and object-graph reconstruction.
      final firstDb = AppDatabase(NativeDatabase(File(dbPath)));
      await firstDb.pendingMediaUploadDao.upsertRecorded(
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: pinnedItemPublicId,
        localFilePath: p.join(tempDir.path, 'recording.wav'),
      );
      await firstDb.pendingMediaUploadDao.markUploading(
        attemptPublicId,
        pinnedItemPublicId,
        mediaPublicId: 'media-1',
        uploadUrl: 'https://minio.example.com/bucket/object?sig=abc',
        uploadUrlExpiresAt: DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch,
      );
      await firstDb.pendingMediaUploadDao.markUploaded(attemptPublicId, pinnedItemPublicId);
      await firstDb.close();

      final secondDb = AppDatabase(NativeDatabase(File(dbPath)));
      addTearDown(secondDb.close);

      final recovered = await secondDb.pendingMediaUploadDao.getRow(attemptPublicId, pinnedItemPublicId);
      expect(recovered, isNotNull);
      expect(recovered!.status, PendingMediaUploadStatus.uploaded.name);

      final mediaRepository = _MockMediaRepository();
      final rawUploadClient = _MockRawUploadClient();
      when(() => mediaRepository.completeUpload(any())).thenAnswer((_) async {});
      when(
        () => rawUploadClient.putFile(any(), any(), contentType: any(named: 'contentType')),
      ).thenAnswer((_) async {});

      final coordinator = MediaUploadCoordinator(
        mediaDao: secondDb.pendingMediaUploadDao,
        outboxDao: secondDb.answerOutboxDao,
        mediaRepository: mediaRepository,
        rawUploadClient: rawUploadClient,
        canary: _FakeCanary(),
      );
      await coordinator.attemptUpload(attemptPublicId, pinnedItemPublicId);

      // Never re-uploaded — only `completeUpload` should have been called,
      // confirming resumption picked up at `completing`, not `uploading`.
      verifyNever(() => rawUploadClient.putFile(any(), any(), contentType: any(named: 'contentType')));
      verify(() => mediaRepository.completeUpload('media-1')).called(1);

      // Reaching `ready` hands off to the ordinary answer outbox and
      // deletes the media-pipeline row (phase-06 Design Constraints).
      final mediaRow = await secondDb.pendingMediaUploadDao.getRow(attemptPublicId, pinnedItemPublicId);
      expect(mediaRow, isNull);
      final outboxRow = await secondDb.answerOutboxDao.getAnswer(attemptPublicId, pinnedItemPublicId);
      expect(outboxRow, isNotNull);
      expect(outboxRow!.payload, 'media-1');
      expect(outboxRow.status, AnswerSyncStatus.pending.name);
    },
  );
}
