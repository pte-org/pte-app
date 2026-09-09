import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/storage/dao/local_violation_dao.dart';

/// Offline-first reporter for lockdown violations. Persists every
/// detected violation locally **before** attempting the backend POST,
/// then attempts the HTTP send; on success the row is marked `sent`,
/// and on any non-2xx / network failure it remains unsent so the next
/// [retryUnsent] pass picks it up. Mirrors the offline-first pattern
/// established by `AnswerOutboxDao` (Phase 2): local is the source of
/// truth in the short term, backend is the source of truth long-term.
///
/// This service deliberately stays above the lockstep `SyncEngine`
/// layer — proctoring violations must reach the backend even when the
/// answer outbox is paused mid-exam, and a synchronous-academic-flow
/// sync engine would gate the violation stream on an unrelated timeout.
class ViolationReporter {
  ViolationReporter({
    required ApiClient apiClient,
    required LocalViolationDao localDao,
    required Logger logger,
  })  : _apiClient = apiClient,
        _localDao = localDao,
        _logger = logger;

  final ApiClient _apiClient;
  final LocalViolationDao _localDao;
  final Logger _logger;

  /// Cooldown gate for [retryUnsent]. Bounded at construction so the
  /// caller cannot accidentally hammer the backend by mistake.
  Duration _retryCooldown = const Duration(seconds: 5);
  DateTime _lastRetryAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Caller-supplied override for tests — replaces the entire
  /// [retryUnsent] body with an injected driver so the retry cadence
  /// can be checked deterministically.
  Future<void> Function()? _retryOverride;

  /// Permits tests to inject a deterministic retry driver. Returns
  /// the previous override so a single test can chain drivers without
  /// leaking state to the next case.
  Future<void> Function()? debugSetRetryOverride(Future<void> Function()? driver) {
    final previous = _retryOverride;
    _retryOverride = driver;
    return previous;
  }

  /// Configures the minimum delay between `retryUnsent` invocations.
  /// Defaults to 5s, which matches the desired user-visible cadence
  /// for retry-on-canary after a transient network outage
  /// (Phase 4 design constraint).
  void debugSetRetryCooldown(Duration cooldown) {
    _retryCooldown = cooldown;
  }

  /// Persists the violation locally, then attempts the backend POST.
  /// Returning before the HTTP attempt fails would silently lose data,
  /// so callers always see the row in `LocalViolationsTable` by the
  /// time this method completes (whether or not the backend accepted
  /// it).
  Future<void> reportViolation(ViolationEvent event) async {
    int? id;
    try {
      id = await _localDao.insert(event);
      _logger.i(
        'Violation saved locally: ${event.type.name} (id: $id)',
      );
    } catch (e, stack) {
      _logger.e('Failed to save violation locally', error: e, stackTrace: stack);
      // Local persistence failed — there is no point retrying the HTTP
      // call, because the next retry cycle would re-insert the row but
      // never have a way to mark it sent. Surface via rethrow so the
      // lockdown service can decide whether to escalate or stay silent.
      rethrow;
    }

    final eventWithId = event.copyWith(id: id);
    await _trySendOne(eventWithId);
  }

  Future<void> _trySendOne(ViolationEvent event) async {
    if (event.id == null) return;
    try {
      await _apiClient.post<void>(
        '/api/proctor/violations',
        data: event.toJson(),
      );
      await _localDao.markSent(event.id!);
      _logger.i('Violation sent to backend: ${event.type.name}');
    } on DioException catch (e) {
      _logger.w(
        'Failed to send violation to backend (will retry later)',
        error: e,
      );
    } on ApiException catch (e) {
      _logger.w(
        'Failed to send violation to backend (will retry later)',
        error: e,
      );
    }
  }

  /// Sweeps unsent rows and tries them again. No-op when no rows are
  /// pending, so this is safe to call on a tight timer. Bounded by
  /// [_retryCooldown] to avoid hammering a struggling backend on every
  /// canary tick.
  Future<void> retryUnsent() async {
    final override = _retryOverride;
    if (override != null) {
      await override();
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastRetryAt) < _retryCooldown) return;
    _lastRetryAt = now;

    final unsent = await _localDao.getUnsent();
    if (unsent.isEmpty) return;

    _logger.i('Retrying ${unsent.length} unsent violation(s)');
    final acked = <int>[];
    for (final row in unsent) {
      final event = LocalViolationDao.fromRow(row);
      try {
        await _apiClient.post<void>(
          '/api/proctor/violations',
          data: event.toJson(),
        );
        if (event.id != null) acked.add(event.id!);
      } on DioException catch (e) {
        _logger.w(
          'Retry failed for violation ${event.id}: ${e.message}',
          error: e,
        );
        // Stop after the first failure — beyond this point the network
        // is genuinely down and further attempts cost battery without
        // making progress.
        break;
      } on ApiException catch (e) {
        // 4xx other than throttle is terminal (bad payload, etc.) —
        // log so a future test can inspect but do not retry forever.
        _logger.w(
          'Retry failed for violation ${event.id}: ${e.message}',
          error: e,
        );
        break;
      }
    }
    if (acked.isNotEmpty) await _localDao.markManySent(acked);
  }

  /// Removes long-synced rows to bound disk usage. Idempotent — the
  /// `sent=true AND timestamp<cutoff` predicate does the right thing
  /// even when called multiple times back-to-back.
  Future<void> cleanupOld({Duration olderThan = const Duration(days: 7)}) async {
    try {
      final removed = await _localDao.deleteOldSent(olderThan: olderThan);
      if (removed > 0) {
        _logger.d('Cleaned up $removed old sent violation row(s)');
      }
    } catch (e, stack) {
      _logger.e(
        'Error cleaning up old violations',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
