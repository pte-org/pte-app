import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/cloudinary_upload_result.dart';
import 'package:pte_app/core/network/media_presign_response.dart';
import 'package:pte_app/core/network/media_repository.dart';
import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/network/raw_upload_client.dart';
import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/rate_limit_backoff.dart';
import 'package:pte_app/core/sync/sync_engine.dart' show PeriodicTimerFactory;

class _MockPendingMediaUploadDao extends Mock
    implements PendingMediaUploadDao {}

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockMediaRepository extends Mock implements MediaRepository {}

class _MockRawUploadClient extends Mock implements RawUploadClient {}

class _FakeCanary implements NetworkCanary {
  _FakeCanary(this.available);

  @override
  final Stream<void> available;

  @override
  Future<void> dispose() async {}
}

PendingMediaUpload _row({
  String attemptPublicId = 'attempt-1',
  String pinnedItemPublicId = 'item-1',
  String localFilePath = '/tmp/attempt-1_item-1.wav',
  String? mediaPublicId,
  String? uploadUrl,
  int? uploadUrlExpiresAt,
  required PendingMediaUploadStatus status,
}) {
  return PendingMediaUpload(
    attemptPublicId: attemptPublicId,
    pinnedItemPublicId: pinnedItemPublicId,
    localFilePath: localFilePath,
    mediaPublicId: mediaPublicId,
    uploadUrl: uploadUrl,
    uploadUrlExpiresAt: uploadUrlExpiresAt,
    cloudinaryApiKey: 'test-key',
    cloudinaryTimestamp: '1700000000',
    cloudinaryUploadSignature: 'test-signature',
    cloudinaryFolder: 'pte/submissions',
    cloudinaryResourceType: 'video',
    cloudinaryPublicId: 'pte/submissions/${mediaPublicId ?? 'media-1'}',
    cloudinaryAssetId: 'asset-1',
    cloudinarySecureUrl:
        'https://res.cloudinary.com/test/video/upload/v1/media-1.wav',
    cloudinaryFormat: 'wav',
    cloudinaryBytes: 1024,
    cloudinaryDurationSeconds: 1,
    cloudinaryVersion: 1,
    cloudinarySignature: 'cloudinary-signature',
    status: status.name,
  );
}

MediaPresignResponse _presign({
  String mediaPublicId = 'media-1',
  String uploadUrl = 'https://api.cloudinary.com/v1_1/test/video/upload',
}) {
  return MediaPresignResponse(
    mediaPublicId: mediaPublicId,
    publicId: 'pte/submissions/$mediaPublicId',
    uploadUrl: uploadUrl,
    apiKey: 'test-key',
    timestamp: '1700000000',
    signature: 'test-signature',
    folder: 'pte/submissions',
    resourceType: 'video',
    expiresInSeconds: 900,
  );
}

CloudinaryUploadResult _uploadResult({
  String publicId = 'pte/submissions/media-1',
}) {
  return CloudinaryUploadResult(
    publicId: publicId,
    assetId: 'asset-1',
    secureUrl: 'https://res.cloudinary.com/test/video/upload/v1/$publicId.wav',
    resourceType: 'video',
    format: 'wav',
    bytes: 1024,
    durationSeconds: 1,
    version: 1,
    signature: 'cloudinary-signature',
  );
}

void main() {
  late _MockPendingMediaUploadDao mediaDao;
  late _MockAnswerOutboxDao outboxDao;
  late _MockMediaRepository mediaRepository;
  late _MockRawUploadClient rawUploadClient;
  late StreamController<void> canaryController;
  late _FakeCanary canary;

  setUpAll(() {
    registerFallbackValue(File('.'));
  });

  setUp(() async {
    mediaDao = _MockPendingMediaUploadDao();
    outboxDao = _MockAnswerOutboxDao();
    mediaRepository = _MockMediaRepository();
    rawUploadClient = _MockRawUploadClient();
    canaryController = StreamController<void>.broadcast();
    canary = _FakeCanary(canaryController.stream);
    final recording = File('/tmp/attempt-1_item-1.wav');
    await recording.parent.create(recursive: true);
    await recording.writeAsBytes(const [0, 1, 2, 3]);
  });

  tearDown(() async {
    await canaryController.close();
    final recording = File('/tmp/attempt-1_item-1.wav');
    if (recording.existsSync()) {
      await recording.delete();
    }
  });

  MediaUploadCoordinator buildCoordinator({
    PeriodicTimerFactory? createPeriodicTimer,
    RateLimitBackoff? backoff,
  }) {
    return MediaUploadCoordinator(
      mediaDao: mediaDao,
      outboxDao: outboxDao,
      mediaRepository: mediaRepository,
      rawUploadClient: rawUploadClient,
      canary: canary,
      createPeriodicTimer: createPeriodicTimer,
      backoff: backoff,
    );
  }

  /// Stubs every DAO/network call needed for a clean recorded -> ready run.
  void stubHappyPath({
    String mediaPublicId = 'media-1',
    String uploadUrl = 'https://minio.example.com/fresh',
  }) {
    when(
      () => mediaRepository.requestPresign(
        any(),
        sizeBytes: any(named: 'sizeBytes'),
      ),
    ).thenAnswer(
      (_) async => _presign(mediaPublicId: mediaPublicId, uploadUrl: uploadUrl),
    );
    when(
      () => mediaDao.markUploading(
        any(),
        any(),
        mediaPublicId: any(named: 'mediaPublicId'),
        uploadUrl: any(named: 'uploadUrl'),
        uploadUrlExpiresAt: any(named: 'uploadUrlExpiresAt'),
        apiKey: any(named: 'apiKey'),
        timestamp: any(named: 'timestamp'),
        signature: any(named: 'signature'),
        folder: any(named: 'folder'),
        resourceType: any(named: 'resourceType'),
        publicId: any(named: 'publicId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => rawUploadClient.upload(
        uploadUrl: any(named: 'uploadUrl'),
        file: any(named: 'file'),
        contentType: any(named: 'contentType'),
        apiKey: any(named: 'apiKey'),
        timestamp: any(named: 'timestamp'),
        signature: any(named: 'signature'),
        folder: any(named: 'folder'),
        publicId: any(named: 'publicId'),
      ),
    ).thenAnswer(
      (_) async => _uploadResult(publicId: 'pte/submissions/$mediaPublicId'),
    );
    when(
      () => mediaDao.markUploaded(any(), any(), result: any(named: 'result')),
    ).thenAnswer((_) async {});
    when(() => mediaDao.markCompleting(any(), any())).thenAnswer((_) async {});
    when(
      () => mediaRepository.completeUpload(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mediaDao.markReady(any(), any())).thenAnswer((_) async {});
    when(
      () => outboxDao.upsertAnswer(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(() => mediaDao.deleteRow(any(), any())).thenAnswer((_) async {});
  }

  group(
    'Happy path — recorded -> ready produces exactly one correct outbox submission (Step 8)',
    () {
      test(
        'attemptUpload on a freshly-recorded row results in exactly one AnswerOutboxDao.upsertAnswer call, '
        'with payload equal to the resolved mediaPublicId — never an intermediate status marker',
        () async {
          final row = _row(status: PendingMediaUploadStatus.recorded);
          when(
            () => mediaDao.getRow('attempt-1', 'item-1'),
          ).thenAnswer((_) async => row);
          stubHappyPath(mediaPublicId: 'resolved-media-id');

          final coordinator = buildCoordinator();
          await coordinator.attemptUpload('attempt-1', 'item-1');

          final captured = verify(
            () => outboxDao.upsertAnswer(
              attemptPublicId: captureAny(named: 'attemptPublicId'),
              pinnedItemPublicId: captureAny(named: 'pinnedItemPublicId'),
              payload: captureAny(named: 'payload'),
            ),
          ).captured;

          // Exactly one call total — no earlier partial state (e.g.
          // "uploading") ever reached the outbox as a payload, and it was
          // not called more than once for this row.
          expect(captured, hasLength(3));
          expect(captured[0], 'attempt-1');
          expect(captured[1], 'item-1');
          expect(captured[2], 'resolved-media-id');

          verify(() => mediaDao.deleteRow('attempt-1', 'item-1')).called(1);
        },
      );

      test(
        'attemptUpload on an already-ready row is a no-op — never re-submits to the outbox',
        () async {
          final row = _row(
            status: PendingMediaUploadStatus.ready,
            mediaPublicId: 'media-1',
          );
          when(
            () => mediaDao.getRow('attempt-1', 'item-1'),
          ).thenAnswer((_) async => row);

          final coordinator = buildCoordinator();
          await coordinator.attemptUpload('attempt-1', 'item-1');

          verifyNever(
            () => outboxDao.upsertAnswer(
              attemptPublicId: any(named: 'attemptPublicId'),
              pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
              payload: any(named: 'payload'),
            ),
          );
        },
      );
    },
  );

  group('Expired-URL failure-driven retry (Step 10, Risks)', () {
    test(
      'a PUT failure recognized as expired (looksExpired = true) triggers a fresh requestPresign call and a '
      'retried PUT against the same local file — not the stale uploadUrl, and never a re-record',
      () async {
        final row = _row(
          status: PendingMediaUploadStatus.uploading,
          mediaPublicId: 'media-1',
          uploadUrl: 'https://minio.example.com/stale',
          // Far in the future so the proactive expiry check does not itself
          // trigger a re-presign — this is the failure-driven path only.
          uploadUrlExpiresAt: DateTime.now()
              .add(const Duration(minutes: 10))
              .millisecondsSinceEpoch,
        );
        when(
          () => mediaDao.getRow('attempt-1', 'item-1'),
        ).thenAnswer((_) async => row);

        var presignCallCount = 0;
        when(
          () => mediaRepository.requestPresign(
            any(),
            sizeBytes: any(named: 'sizeBytes'),
          ),
        ).thenAnswer((_) async {
          presignCallCount++;
          return _presign(
            mediaPublicId: 'media-1',
            uploadUrl: 'https://api.cloudinary.com/fresh',
          );
        });
        when(
          () => mediaDao.markUploading(
            any(),
            any(),
            mediaPublicId: any(named: 'mediaPublicId'),
            uploadUrl: any(named: 'uploadUrl'),
            uploadUrlExpiresAt: any(named: 'uploadUrlExpiresAt'),
            apiKey: any(named: 'apiKey'),
            timestamp: any(named: 'timestamp'),
            signature: any(named: 'signature'),
            folder: any(named: 'folder'),
            resourceType: any(named: 'resourceType'),
            publicId: any(named: 'publicId'),
          ),
        ).thenAnswer((_) async {});

        final putUrls = <String>[];
        final putFilePaths = <String>[];
        when(
          () => rawUploadClient.upload(
            uploadUrl: any(named: 'uploadUrl'),
            file: any(named: 'file'),
            contentType: any(named: 'contentType'),
            apiKey: any(named: 'apiKey'),
            timestamp: any(named: 'timestamp'),
            signature: any(named: 'signature'),
            folder: any(named: 'folder'),
            publicId: any(named: 'publicId'),
          ),
        ).thenAnswer((invocation) async {
          final url = invocation.namedArguments[#uploadUrl] as String;
          final file = invocation.namedArguments[#file] as File;
          putUrls.add(url);
          putFilePaths.add(file.path);
          if (putUrls.length == 1) {
            throw const RawUploadException(
              looksExpired: true,
              message: 'signature expired',
            );
          }
          return _uploadResult();
        });
        when(
          () =>
              mediaDao.markUploaded(any(), any(), result: any(named: 'result')),
        ).thenAnswer((_) async {});
        when(
          () => mediaDao.markCompleting(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mediaRepository.completeUpload(any(), any()),
        ).thenAnswer((_) async {});
        when(() => mediaDao.markReady(any(), any())).thenAnswer((_) async {});
        when(
          () => outboxDao.upsertAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});
        when(() => mediaDao.deleteRow(any(), any())).thenAnswer((_) async {});

        final coordinator = buildCoordinator();
        await coordinator.attemptUpload('attempt-1', 'item-1');

        expect(putUrls, [
          'https://minio.example.com/stale',
          'https://api.cloudinary.com/fresh',
        ]);
        expect(putFilePaths, [
          '/tmp/attempt-1_item-1.wav',
          '/tmp/attempt-1_item-1.wav',
        ]);
        expect(presignCallCount, 1);
        verify(
          () => outboxDao.upsertAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            payload: 'media-1',
          ),
        ).called(1);
      },
    );

    test(
      'a PUT failure NOT recognized as expired (e.g. a 500) is never retried with a fresh presign — it '
      'propagates and leaves the row for the next canary/periodic trigger',
      () async {
        final row = _row(
          status: PendingMediaUploadStatus.uploading,
          mediaPublicId: 'media-1',
          uploadUrl: 'https://minio.example.com/stale',
          uploadUrlExpiresAt: DateTime.now()
              .add(const Duration(minutes: 10))
              .millisecondsSinceEpoch,
        );
        when(
          () => mediaDao.getRow('attempt-1', 'item-1'),
        ).thenAnswer((_) async => row);
        when(
          () => mediaRepository.requestPresign(
            any(),
            sizeBytes: any(named: 'sizeBytes'),
          ),
        ).thenAnswer(
          (_) async => _presign(
            mediaPublicId: 'media-1',
            uploadUrl: 'https://api.cloudinary.com/fresh',
          ),
        );
        when(
          () => rawUploadClient.upload(
            uploadUrl: any(named: 'uploadUrl'),
            file: any(named: 'file'),
            contentType: any(named: 'contentType'),
            apiKey: any(named: 'apiKey'),
            timestamp: any(named: 'timestamp'),
            signature: any(named: 'signature'),
            folder: any(named: 'folder'),
            publicId: any(named: 'publicId'),
          ),
        ).thenThrow(
          const RawUploadException(
            looksExpired: false,
            message: 'server error',
          ),
        );
        when(
          () => mediaDao.markError(any(), any(), any()),
        ).thenAnswer((_) async {});

        final coordinator = buildCoordinator();
        await coordinator.attemptUpload('attempt-1', 'item-1');

        verifyNever(
          () => mediaRepository.requestPresign(
            any(),
            sizeBytes: any(named: 'sizeBytes'),
          ),
        );
        verify(
          () => mediaDao.markError('attempt-1', 'item-1', any()),
        ).called(1);
        verifyNever(
          () => outboxDao.upsertAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        );
      },
    );
  });

  group('Process-death resumption (Step 11)', () {
    test(
      'a row persisted at `uploaded` via a real Drift database resumes at completing/complete on a freshly '
      'reconstructed coordinator — never re-presigning or re-uploading',
      () async {
        final dir = await Directory.systemTemp.createTemp(
          'media_upload_coordinator_process_death_test',
        );
        final dbFile = File('${dir.path}/test.sqlite');
        addTearDown(() async {
          if (dir.existsSync()) dir.deleteSync(recursive: true);
        });

        final firstDb = AppDatabase(NativeDatabase(dbFile));
        await firstDb.pendingMediaUploadDao.upsertRecorded(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          localFilePath: '/tmp/attempt-1_item-1.wav',
        );
        await firstDb.pendingMediaUploadDao.markUploading(
          'attempt-1',
          'item-1',
          mediaPublicId: 'media-1',
          uploadUrl: 'https://minio.example.com/stale',
          uploadUrlExpiresAt: DateTime.now()
              .add(const Duration(minutes: 10))
              .millisecondsSinceEpoch,
          apiKey: 'test-key',
          timestamp: '1700000000',
          signature: 'test-signature',
          folder: 'pte/submissions',
          resourceType: 'video',
          publicId: 'pte/submissions/media-1',
        );
        await firstDb.pendingMediaUploadDao.markUploaded(
          'attempt-1',
          'item-1',
          result: _uploadResult(),
        );
        await firstDb.close();

        final secondDb = AppDatabase(NativeDatabase(dbFile));
        addTearDown(() async => secondDb.close());

        when(() => mediaDao.getRow('attempt-1', 'item-1')).thenAnswer(
          (_) => secondDb.pendingMediaUploadDao.getRow('attempt-1', 'item-1'),
        );
        when(
          () => mediaRepository.completeUpload(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => outboxDao.upsertAnswer(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        final coordinator = MediaUploadCoordinator(
          mediaDao: secondDb.pendingMediaUploadDao,
          outboxDao: outboxDao,
          mediaRepository: mediaRepository,
          rawUploadClient: rawUploadClient,
          canary: canary,
        );

        await coordinator.attemptUpload('attempt-1', 'item-1');

        verify(
          () => mediaRepository.completeUpload('media-1', any()),
        ).called(1);
        verifyNever(
          () => mediaRepository.requestPresign(
            any(),
            sizeBytes: any(named: 'sizeBytes'),
          ),
        );
        verifyNever(
          () => rawUploadClient.upload(
            uploadUrl: any(named: 'uploadUrl'),
            file: any(named: 'file'),
            contentType: any(named: 'contentType'),
            apiKey: any(named: 'apiKey'),
            timestamp: any(named: 'timestamp'),
            signature: any(named: 'signature'),
            folder: any(named: 'folder'),
            publicId: any(named: 'publicId'),
          ),
        );
        verify(
          () => outboxDao.upsertAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            payload: 'media-1',
          ),
        ).called(1);

        final rowAfter = await secondDb.pendingMediaUploadDao.getRow(
          'attempt-1',
          'item-1',
        );
        expect(
          rowAfter,
          isNull,
          reason:
              'a row that reached ready is deleted, handed off to the answer outbox',
        );
      },
    );
  });

  group(
    'Offline-recorded row retried via canary/periodic triggers, not just at recording-stop time (Step 12)',
    () {
      test(
        'a canary connectivity-restore event advances a recorded-status row through the full pipeline',
        () async {
          final row = _row(status: PendingMediaUploadStatus.recorded);
          when(() => mediaDao.queryNonReady()).thenAnswer((_) async => [row]);
          stubHappyPath();

          final coordinator = buildCoordinator();
          coordinator.start();
          addTearDown(coordinator.stop);

          verifyNever(
            () => mediaRepository.requestPresign(
              any(),
              sizeBytes: any(named: 'sizeBytes'),
            ),
          );

          canaryController.add(null);
          await Future<void>.delayed(const Duration(milliseconds: 20));

          verify(
            () => outboxDao.upsertAnswer(
              attemptPublicId: 'attempt-1',
              pinnedItemPublicId: 'item-1',
              payload: 'media-1',
            ),
          ).called(1);
        },
      );

      test(
        'a periodic fallback tick (no canary event at all) also advances a recorded-status row',
        () async {
          final row = _row(status: PendingMediaUploadStatus.recorded);
          when(() => mediaDao.queryNonReady()).thenAnswer((_) async => [row]);
          stubHappyPath();

          void Function(Timer)? periodicCallback;
          Timer fakePeriodicTimer(
            Duration period,
            void Function(Timer) callback,
          ) {
            periodicCallback = callback;
            return Timer(const Duration(days: 999), () {});
          }

          final coordinator = buildCoordinator(
            createPeriodicTimer: fakePeriodicTimer,
          );
          coordinator.start();
          addTearDown(coordinator.stop);

          verifyNever(
            () => mediaRepository.requestPresign(
              any(),
              sizeBytes: any(named: 'sizeBytes'),
            ),
          );
          expect(periodicCallback, isNotNull);

          periodicCallback!(Timer(Duration.zero, () {}));
          await Future<void>.delayed(const Duration(milliseconds: 20));

          verify(
            () => outboxDao.upsertAnswer(
              attemptPublicId: 'attempt-1',
              pinnedItemPublicId: 'item-1',
              payload: 'media-1',
            ),
          ).called(1);
        },
      );

      test(
        'start() is idempotent — a second call does not register a second canary subscription/periodic timer',
        () async {
          var timerFactoryCalls = 0;
          Timer fakePeriodicTimer(
            Duration period,
            void Function(Timer) callback,
          ) {
            timerFactoryCalls++;
            return Timer(const Duration(days: 999), () {});
          }

          final coordinator = buildCoordinator(
            createPeriodicTimer: fakePeriodicTimer,
          );
          coordinator.start();
          coordinator.start();
          addTearDown(coordinator.stop);

          expect(timerFactoryCalls, 1);
        },
      );
    },
  );

  group(
    '429 rate-limit backoff via shared RateLimitBackoff (Step 11 — mirrors SyncEngine Step 9)',
    () {
      test(
        'a RateLimitException from requestPresign suppresses further upload attempts (attemptUpload and scanAll '
        'both return immediately) until the fake-clock backoff window elapses — proving the shared RateLimitBackoff '
        'class behaves identically at this call site too',
        () async {
          var currentTime = DateTime(2026, 1, 1, 0, 0, 0);
          final backoff = RateLimitBackoff(
            baseInterval: const Duration(seconds: 1),
            maxInterval: const Duration(seconds: 32),
            now: () => currentTime,
          );

          final row = _row(status: PendingMediaUploadStatus.recorded);
          when(
            () => mediaDao.getRow('attempt-1', 'item-1'),
          ).thenAnswer((_) async => row);
          when(() => mediaDao.queryNonReady()).thenAnswer((_) async => [row]);
          when(
            () => mediaDao.markError(any(), any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mediaRepository.requestPresign(
              any(),
              sizeBytes: any(named: 'sizeBytes'),
            ),
          ).thenThrow(const RateLimitException('Rate limited (429)'));

          final coordinator = buildCoordinator(backoff: backoff);

          await coordinator.attemptUpload('attempt-1', 'item-1');
          verify(
            () => mediaRepository.requestPresign(
              any(),
              sizeBytes: any(named: 'sizeBytes'),
            ),
          ).called(1);
          expect(
            backoff.isActive,
            isTrue,
            reason: 'a 429 from presign must arm the cooldown immediately',
          );
          // RateLimitException is NOT the generic catch-all path — no
          // markError call for this case (that's only the unrecognized
          // catch-all branch).
          verifyNever(() => mediaDao.markError(any(), any(), any()));

          // Further attempts (both the direct attemptUpload and the
          // background scanAll loop) must return immediately while the
          // cooldown is active — no additional requestPresign call.
          await coordinator.attemptUpload('attempt-1', 'item-1');
          await coordinator.scanAll();
          verifyNever(
            () => mediaRepository.requestPresign(
              any(),
              sizeBytes: any(named: 'sizeBytes'),
            ),
          );

          // Advance the fake clock past the 1s cooldown window.
          currentTime = currentTime.add(const Duration(seconds: 2));
          expect(
            backoff.isActive,
            isFalse,
            reason: 'the cooldown window has elapsed per the fake clock',
          );

          // Now stub the full happy path so the next attempt succeeds and
          // resets the backoff.
          stubHappyPath();
          await coordinator.attemptUpload('attempt-1', 'item-1');
          verify(
            () => outboxDao.upsertAnswer(
              attemptPublicId: 'attempt-1',
              pinnedItemPublicId: 'item-1',
              payload: 'media-1',
            ),
          ).called(1);
          expect(
            backoff.isActive,
            isFalse,
            reason: 'a successful upload must reset() the backoff',
          );
        },
      );

      test(
        'a RateLimitException from completeUpload also arms the shared backoff and suppresses further attempts',
        () async {
          final currentTime = DateTime(2026, 1, 1, 0, 0, 0);
          final backoff = RateLimitBackoff(now: () => currentTime);

          final row = _row(
            status: PendingMediaUploadStatus.uploaded,
            mediaPublicId: 'media-1',
            uploadUrl: 'https://minio.example.com/fresh',
            uploadUrlExpiresAt: DateTime.now()
                .add(const Duration(minutes: 10))
                .millisecondsSinceEpoch,
          );
          when(
            () => mediaDao.getRow('attempt-1', 'item-1'),
          ).thenAnswer((_) async => row);
          when(
            () => mediaDao.markCompleting(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mediaRepository.completeUpload(any(), any()),
          ).thenThrow(const RateLimitException('Rate limited (429)'));

          final coordinator = buildCoordinator(backoff: backoff);
          await coordinator.attemptUpload('attempt-1', 'item-1');

          expect(backoff.isActive, isTrue);
          verifyNever(() => mediaDao.markError(any(), any(), any()));
          verifyNever(() => mediaDao.markReady(any(), any()));
        },
      );
    },
  );

  group(
    'Regression: per-row in-flight guard prevents concurrent double-processing',
    () {
      test(
        'attemptUpload and scanAll racing for the same row never both trigger requestPresign — the second '
        'concurrent attempt is a no-op, not a duplicate presign call',
        () async {
          final row = _row(status: PendingMediaUploadStatus.recorded);
          when(
            () => mediaDao.getRow('attempt-1', 'item-1'),
          ).thenAnswer((_) async => row);
          when(() => mediaDao.queryNonReady()).thenAnswer((_) async => [row]);

          final presignCompleter = Completer<MediaPresignResponse>();
          var presignCallCount = 0;
          when(
            () => mediaRepository.requestPresign(
              any(),
              sizeBytes: any(named: 'sizeBytes'),
            ),
          ).thenAnswer((_) {
            presignCallCount++;
            return presignCompleter.future;
          });
          when(
            () => mediaDao.markUploading(
              any(),
              any(),
              mediaPublicId: any(named: 'mediaPublicId'),
              uploadUrl: any(named: 'uploadUrl'),
              uploadUrlExpiresAt: any(named: 'uploadUrlExpiresAt'),
              apiKey: any(named: 'apiKey'),
              timestamp: any(named: 'timestamp'),
              signature: any(named: 'signature'),
              folder: any(named: 'folder'),
              resourceType: any(named: 'resourceType'),
              publicId: any(named: 'publicId'),
            ),
          ).thenAnswer((_) async {});
          when(
            () => rawUploadClient.upload(
              uploadUrl: any(named: 'uploadUrl'),
              file: any(named: 'file'),
              contentType: any(named: 'contentType'),
              apiKey: any(named: 'apiKey'),
              timestamp: any(named: 'timestamp'),
              signature: any(named: 'signature'),
              folder: any(named: 'folder'),
              publicId: any(named: 'publicId'),
            ),
          ).thenAnswer((_) async => _uploadResult());
          when(
            () => mediaDao.markUploaded(
              any(),
              any(),
              result: any(named: 'result'),
            ),
          ).thenAnswer((_) async {});
          when(
            () => mediaDao.markCompleting(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mediaRepository.completeUpload(any(), any()),
          ).thenAnswer((_) async {});
          when(() => mediaDao.markReady(any(), any())).thenAnswer((_) async {});
          when(
            () => outboxDao.upsertAnswer(
              attemptPublicId: any(named: 'attemptPublicId'),
              pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
              payload: any(named: 'payload'),
            ),
          ).thenAnswer((_) async {});
          when(() => mediaDao.deleteRow(any(), any())).thenAnswer((_) async {});

          final coordinator = buildCoordinator();

          final f1 = coordinator.attemptUpload('attempt-1', 'item-1');
          final f2 = coordinator.scanAll();
          // Let both reach (and race on) the in-flight guard before the
          // presign call resolves.
          await Future<void>.delayed(const Duration(milliseconds: 20));

          expect(
            presignCallCount,
            1,
            reason:
                'the guard must stop the second caller before it re-requests a presign',
          );

          presignCompleter.complete(
            _presign(
              mediaPublicId: 'media-1',
              uploadUrl: 'https://api.cloudinary.com/fresh',
            ),
          );
          await Future.wait([f1, f2]);

          expect(presignCallCount, 1);
          verify(
            () => outboxDao.upsertAnswer(
              attemptPublicId: 'attempt-1',
              pinnedItemPublicId: 'item-1',
              payload: 'media-1',
            ),
          ).called(1);
        },
      );
    },
  );
}
