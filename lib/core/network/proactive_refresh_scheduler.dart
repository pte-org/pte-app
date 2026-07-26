import 'dart:async';

import '../storage/token_store.dart';

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
    DateTime Function()? now,
    TimerFactory? createTimer,
  })  : _safetyMargin = safetyMargin,
        _now = now ?? DateTime.now,
        _createTimer = createTimer ?? Timer.new;

  final TokenStore tokenStore;
  final Future<void> Function() onRefreshDue;
  final Duration _safetyMargin;
  final DateTime Function() _now;
  final TimerFactory _createTimer;

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
    _timer = _createTimer(delay, () {
      unawaited(onRefreshDue());
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
