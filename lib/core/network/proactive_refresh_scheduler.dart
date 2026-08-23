import 'dart:async';

import 'package:logger/logger.dart';

import 'package:pte_app/core/storage/token_store.dart';

/// Injectable so tests drive scheduling deterministically instead of
/// waiting on a real [Timer] — same pattern Phase 4's `TimerService` uses
/// for its poll cadence.
typedef TimerFactory = Timer Function(Duration delay, void Function() callback);

/// Refreshes the access token ahead of its 900-second expiry, independent
/// of any request actually failing with 401 — the reactive
/// [TokenRefreshInterceptor] path is a safety net, not the primary
/// mechanism (phase-01 Design Constraints).
class ProactiveRefreshScheduler {
  ProactiveRefreshScheduler({
    required this.tokenStore,
    required this.onRefreshDue,
    Duration safetyMargin = const Duration(seconds: 60),
    Duration retryDelay = const Duration(seconds: 30),
    DateTime Function()? now,
    TimerFactory? createTimer,
    Logger? logger,
  })  : _safetyMargin = safetyMargin,
        _retryDelay = retryDelay,
        _now = now ?? DateTime.now,
        _createTimer = createTimer ?? Timer.new,
        _logger = logger ?? Logger();

  final TokenStore tokenStore;
  final Future<void> Function() onRefreshDue;
  final Duration _safetyMargin;
  final Duration _retryDelay;
  final DateTime Function() _now;
  final TimerFactory _createTimer;
  final Logger _logger;

  Timer? _timer;

  /// Reads [TokenStore.accessTokenExpiresAt] and schedules [onRefreshDue]
  /// to fire [_safetyMargin] before that deadline. No-op if no token is
  /// currently stored.
  void scheduleFromTokenStore() {
    final expiresAt = tokenStore.accessTokenExpiresAt;
    if (expiresAt == null) return;

    final rawDelay = expiresAt.difference(_now()) - _safetyMargin;
    final delay = rawDelay.isNegative ? Duration.zero : rawDelay;

    _timer?.cancel();
    _timer = _createTimer(delay, _fireRefresh);
  }

  Future<void> _fireRefresh() async {
    try {
      await onRefreshDue();
      // Re-arm for the next cycle — this must fire again on every
      // subsequent expiry, not just once after login (QUAL-101, Phase 1
      // quality gate), or every cycle after the first silently falls back
      // to the reactive 401 path.
      scheduleFromTokenStore();
    } catch (e, stackTrace) {
      // A proactive-refresh failure must not silently strand the app on
      // the reactive 401-interceptor as its only remaining fallback —
      // re-arm a short retry instead of dropping the failure (QUAL-003,
      // Phase 1 quality gate).
      _logger.w('Proactive token refresh failed, retrying in $_retryDelay', error: e, stackTrace: stackTrace);
      _timer = _createTimer(_retryDelay, _fireRefresh);
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
