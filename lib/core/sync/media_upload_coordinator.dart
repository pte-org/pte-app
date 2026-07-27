import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../network/api_exceptions.dart';
import '../network/media_repository.dart';
import '../network/network_canary.dart';
import '../network/raw_upload_client.dart';
import '../storage/app_database.dart';
import '../storage/dao/answer_outbox_dao.dart';
import '../storage/dao/pending_media_upload_dao.dart';
import '../storage/pending_media_upload_status.dart';
import 'rate_limit_backoff.dart';
import 'sync_engine.dart';

/// Drives every `PendingMediaUploadTable` row through presign → upload →
/// complete, then hands the resolved `mediaPublicId` to Phase 2's answer
/// outbox. A separate track from [SyncEngine] on purpose — it never
/// touches `AnswerOutboxTable` directly except for the single final
/// `upsertAnswer` call once a row reaches
/// [PendingMediaUploadStatus.ready] (phase-06 Design Constraints).
///
/// Reuses [SyncEngine]'s [PeriodicTimerFactory] typedef and the shared
/// [NetworkCanary] singleton instance rather than standing up a second
/// independent canary/timer pair — a literal shared `Timer` isn't a
/// coherent concept between two unrelated consumers with different
/// callbacks, so this coordinator runs its own periodic timer using the
/// same injectable-timer shape Phase 2 already established for
/// deterministic tests.
class MediaUploadCoordinator {
  MediaUploadCoordinator({
    required PendingMediaUploadDao mediaDao,
    required AnswerOutboxDao outboxDao,
    required MediaRepository mediaRepository,
    required RawUploadClient rawUploadClient,
    required NetworkCanary canary,
    Duration periodicInterval = const Duration(seconds: 30),
    PeriodicTimerFactory? createPeriodicTimer,
    Logger? logger,
    String contentType = 'audio/wav',
    RateLimitBackoff? backoff,
  }) : _mediaDao = mediaDao,
       _outboxDao = outboxDao,
       _mediaRepository = mediaRepository,
       _rawUploadClient = rawUploadClient,
       _canary = canary,
       _periodicInterval = periodicInterval,
       _createPeriodicTimer = createPeriodicTimer ?? Timer.periodic,
       _logger = logger ?? Logger(),
       _contentType = contentType,
       _backoff = backoff ?? RateLimitBackoff();

  final PendingMediaUploadDao _mediaDao;
  final AnswerOutboxDao _outboxDao;
  final MediaRepository _mediaRepository;
  final RawUploadClient _rawUploadClient;
  final NetworkCanary _canary;
  final Duration _periodicInterval;
  final PeriodicTimerFactory _createPeriodicTimer;
  final Logger _logger;
  final String _contentType;
  final RateLimitBackoff _backoff;

  StreamSubscription<void>? _canarySubscription;
  Timer? _periodicTimer;
  bool _isScanning = false;

  /// Guards a single row against concurrent advancement from two different
  /// triggers — e.g. [attemptUpload] firing right after recording stops at
  /// the same moment a periodic [scanAll] tick reaches the same row. Keyed
  /// on `attemptPublicId|pinnedItemPublicId`; [scanAll]'s own `_isScanning`
  /// only single-flights the scan loop itself, not a directly-called
  /// [attemptUpload] racing it.
  final Set<String> _inFlightRows = {};

  /// Starts the background scan loop — a connectivity-restore subscription
  /// plus a periodic fallback tick, so an offline-recorded row is retried
  /// beyond its initial post-recording attempt (phase-06 Design
  /// Constraints). Safe to call more than once; a second call is a no-op
  /// while already running.
  void start() {
    if (_canarySubscription != null || _periodicTimer != null) return;
    _canarySubscription = _canary.available.listen((_) => unawaited(scanAll()));
    _periodicTimer = _createPeriodicTimer(_periodicInterval, (_) => unawaited(scanAll()));
  }

  void stop() {
    unawaited(_canarySubscription?.cancel());
    _canarySubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Immediate one-off attempt for a specific row — called right after
  /// recording stops, independent of the scan loop's cadence.
  Future<void> attemptUpload(String attemptPublicId, String pinnedItemPublicId) async {
    if (_backoff.isActive) return;
    final row = await _mediaDao.getRow(attemptPublicId, pinnedItemPublicId);
    if (row == null || row.status == PendingMediaUploadStatus.ready.name) return;
    await _advance(row);
  }

  /// Scans every non-[PendingMediaUploadStatus.ready] row and attempts to
  /// advance each one. Single-flight, mirroring [SyncEngine._flush]'s
  /// `_isFlushing` guard.
  Future<void> scanAll() async {
    if (_isScanning || _backoff.isActive) return;
    _isScanning = true;
    try {
      final rows = await _mediaDao.queryNonReady();
      for (final row in rows) {
        await _advance(row);
      }
    } finally {
      _isScanning = false;
    }
  }

  Future<void> _advance(PendingMediaUpload initial) async {
    final key = '${initial.attemptPublicId}|${initial.pinnedItemPublicId}';
    if (!_inFlightRows.add(key)) return;
    try {
      var current = initial;
      try {
        while (current.status != PendingMediaUploadStatus.ready.name) {
          current = await switch (PendingMediaUploadStatus.values.byName(current.status)) {
            PendingMediaUploadStatus.recorded => _presign(current),
            PendingMediaUploadStatus.uploading => _upload(current),
            PendingMediaUploadStatus.uploaded || PendingMediaUploadStatus.completing => _complete(current),
            PendingMediaUploadStatus.ready => current,
          };
        }
        await _submitToOutbox(current);
        _backoff.reset();
      } on RateLimitException catch (e) {
        // Shares the same gateway rate limit as SyncEngine's answer
        // submission (requestPresign/completeUpload both go through
        // ApiClient) — back off every row, not just this one, until the
        // cooldown elapses (phase-07 Design Constraints). The raw PUT to
        // MinIO never throws this: it doesn't go through the gateway.
        _backoff.registerRateLimited(retryAfter: e.retryAfter);
        _logger.w('Media upload rate-limited, backing off', error: e);
      } catch (e, stackTrace) {
        // Left at whatever status it reached — retried on the next
        // canary/periodic trigger, mirroring SyncEngine's leave-pending
        // behavior. No terminal-rejected equivalent exists for the media
        // pipeline (phase-06 Risks: unbounded retry is the correct
        // behavior here, not a gap).
        _logger.w(
          'Media upload advance failed for ${current.pinnedItemPublicId}, left at ${current.status} for next tick',
          error: e,
          stackTrace: stackTrace,
        );
        await _mediaDao.markError(current.attemptPublicId, current.pinnedItemPublicId, e.toString());
      }
    } finally {
      _inFlightRows.remove(key);
    }
  }

  Future<PendingMediaUpload> _presign(PendingMediaUpload row) async {
    final presign = await _mediaRepository.requestPresign(_contentType);
    final expiresAt = DateTime.now().add(Duration(seconds: presign.expiresInSeconds)).millisecondsSinceEpoch;
    await _mediaDao.markUploading(
      row.attemptPublicId,
      row.pinnedItemPublicId,
      mediaPublicId: presign.mediaPublicId,
      uploadUrl: presign.uploadUrl,
      uploadUrlExpiresAt: expiresAt,
    );
    // Built locally rather than re-queried — every field just written is
    // already known here, and nothing else can write to this row
    // concurrently (single coordinator, per-row in-flight guard).
    return row.copyWith(
      mediaPublicId: Value(presign.mediaPublicId),
      uploadUrl: Value(presign.uploadUrl),
      uploadUrlExpiresAt: Value(expiresAt),
      status: PendingMediaUploadStatus.uploading.name,
    );
  }

  Future<PendingMediaUpload> _upload(PendingMediaUpload row) async {
    final file = File(row.localFilePath);
    var current = row;

    // Proactive check to avoid a doomed request — the failure-driven
    // fallback below still exists regardless, since a URL can expire in
    // the gap between this check and the request actually landing
    // (phase-06 Design Constraints).
    final expiresAt = current.uploadUrlExpiresAt;
    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      current = await _presign(current);
    }

    // Retry once with a fresh presign if the URL turns out expired/invalid.
    // Never re-record — only the PUT is repeated, against the same local file.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _rawUploadClient.putFile(current.uploadUrl!, file, contentType: _contentType);
        break;
      } on RawUploadException catch (e) {
        if (!e.looksExpired || attempt == 1) rethrow;
        current = await _presign(current);
      }
    }

    await _mediaDao.markUploaded(current.attemptPublicId, current.pinnedItemPublicId);
    return current.copyWith(status: PendingMediaUploadStatus.uploaded.name);
  }

  Future<PendingMediaUpload> _complete(PendingMediaUpload row) async {
    await _mediaDao.markCompleting(row.attemptPublicId, row.pinnedItemPublicId);
    await _mediaRepository.completeUpload(row.mediaPublicId!);
    await _mediaDao.markReady(row.attemptPublicId, row.pinnedItemPublicId);
    return row.copyWith(status: PendingMediaUploadStatus.ready.name);
  }

  Future<void> _submitToOutbox(PendingMediaUpload row) async {
    await _outboxDao.upsertAnswer(
      attemptPublicId: row.attemptPublicId,
      pinnedItemPublicId: row.pinnedItemPublicId,
      payload: row.mediaPublicId!,
    );
    await _mediaDao.deleteRow(row.attemptPublicId, row.pinnedItemPublicId);
  }
}
