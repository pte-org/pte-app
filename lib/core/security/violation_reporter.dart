import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/storage/dao/local_violation_dao.dart';

/// Offline-first reporter for lockdown violations. A row is persisted before
/// the first HTTP attempt and remains available until the authenticated
/// attempt endpoint returns either a normal or duplicate receipt.
class ViolationReporter {
  ViolationReporter({
    required ApiClient apiClient,
    required LocalViolationDao localDao,
    required Logger logger,
  }) : _apiClient = apiClient,
       _localDao = localDao,
       _logger = logger;

  final ApiClient _apiClient;
  final LocalViolationDao _localDao;
  final Logger _logger;

  Duration _retryCooldown = const Duration(seconds: 5);
  DateTime _lastRetryAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _retryInProgress = false;

  static const String _endpointSuffix = '/security-violations';

  Future<void> Function()? _retryOverride;

  Future<void> Function()? debugSetRetryOverride(
    Future<void> Function()? driver,
  ) {
    final previous = _retryOverride;
    _retryOverride = driver;
    return previous;
  }

  void debugSetRetryCooldown(Duration cooldown) {
    _retryCooldown = cooldown;
  }

  /// Persists first, then attempts delivery. The same event id is retained in
  /// the row and is sent again if the first request times out after a server
  /// commit.
  Future<void> reportViolation(ViolationEvent event) async {
    int? id;
    try {
      id = await _localDao.insert(event);
      _logger.i('Violation saved locally: ${event.type.name} (id: $id)');
    } catch (e, stack) {
      _logger.e(
        'Failed to save violation locally',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }

    await _trySendOne(event.copyWith(id: id));
  }

  Future<void> _trySendOne(ViolationEvent event) async {
    final id = event.id;
    if (id == null) return;
    try {
      await _post(event);
      await _localDao.markSent(id);
      _logger.i('Violation sent to backend: ${event.type.name}');
    } on DioException catch (e) {
      if (_isTerminal(e)) {
        await _markTerminal(event, e.toString());
      } else {
        _logger.w(
          'Failed to send violation to backend (will retry later)',
          error: e,
        );
      }
    } on ApiException catch (e) {
      if (_isTerminal(e)) {
        await _markTerminal(event, e.message);
      } else {
        _logger.w(
          'Failed to send violation to backend (will retry later)',
          error: e,
        );
      }
    }
  }

  /// Sweeps pending rows on reconnect or on the coordinator's periodic tick.
  /// The single-flight guard protects both triggers from overlapping.
  Future<void> retryUnsent() async {
    if (_retryInProgress) return;
    _retryInProgress = true;
    try {
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
        late final ViolationEvent event;
        try {
          event = LocalViolationDao.fromRow(row);
        } on UnknownViolationTypeException catch (e) {
          await _localDao.markTerminal(row.id, e.toString());
          _logger.w('Terminalized violation ${row.id}: $e');
          continue;
        }

        try {
          await _post(event);
          acked.add(event.id!);
        } on DioException catch (e) {
          if (_isTerminal(e)) {
            await _markTerminal(event, e.toString());
            continue;
          }
          _logger.w(
            'Retry failed for violation ${event.id}: ${e.message}',
            error: e,
          );
          break;
        } on ApiException catch (e) {
          if (_isTerminal(e)) {
            await _markTerminal(event, e.message);
            continue;
          }
          _logger.w(
            'Retry failed for violation ${event.id}: ${e.message}',
            error: e,
          );
          break;
        }
      }
      if (acked.isNotEmpty) await _localDao.markManySent(acked);
    } finally {
      _retryInProgress = false;
    }
  }

  Future<void> _post(ViolationEvent event) {
    return _apiClient
        .post<void>(
          '/api/v1/attempts/${event.attemptPublicId}$_endpointSuffix',
          data: event.toJson(),
        )
        .then((_) {});
  }

  Future<void> _markTerminal(ViolationEvent event, String reason) async {
    final id = event.id;
    if (id == null) return;
    await _localDao.markTerminal(id, reason);
    _logger.w('Terminalized violation $id: $reason');
  }

  bool _isTerminal(Object error) {
    if (error is ValidationException ||
        error is ConflictException ||
        error is ForbiddenException ||
        error is NotFoundException ||
        error is GoneException) {
      return true;
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      return status != null &&
          status >= 400 &&
          status < 500 &&
          status != 401 &&
          status != 429;
    }
    return false;
  }

  /// Removes acknowledged rows after the retention window. Terminal rows
  /// remain available for diagnostics until a later retention policy owns
  /// their cleanup.
  Future<void> cleanupOld({
    Duration olderThan = const Duration(days: 7),
  }) async {
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
