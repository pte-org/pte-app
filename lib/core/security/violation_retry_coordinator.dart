import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';

import 'package:pte_app/core/network/network_canary.dart';
import 'package:pte_app/core/security/violation_reporter.dart';
import 'package:pte_app/core/sync/sync_engine.dart' show PeriodicTimerFactory;

/// Owns the independent background delivery loop for security audit rows.
/// It is deliberately not tied to an attempt Bloc, answer sync, timer, or
/// navigation state: a row can outlive the screen that created it.
class ViolationRetryCoordinator with WidgetsBindingObserver {
  ViolationRetryCoordinator({
    required ViolationReporter reporter,
    required NetworkCanary canary,
    Duration periodicInterval = const Duration(seconds: 30),
    PeriodicTimerFactory? createPeriodicTimer,
    Logger? logger,
  }) : _reporter = reporter,
       _canary = canary,
       _periodicInterval = periodicInterval,
       _createPeriodicTimer = createPeriodicTimer ?? Timer.periodic,
       _logger = logger ?? Logger();

  final ViolationReporter _reporter;
  final NetworkCanary _canary;
  final Duration _periodicInterval;
  final PeriodicTimerFactory _createPeriodicTimer;
  final Logger _logger;

  StreamSubscription<void>? _canarySubscription;
  Timer? _periodicTimer;
  bool _started = false;
  bool _sweepInProgress = false;

  bool get isStarted => _started;

  /// Starts exactly one reconnect listener and one bounded fallback timer.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _canarySubscription = _canary.available.listen((_) => unawaited(_sweep()));
    _periodicTimer = _createPeriodicTimer(
      _periodicInterval,
      (_) => unawaited(_sweep()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(dispose());
    }
  }

  Future<void> _sweep() async {
    if (!_started || _sweepInProgress) return;
    _sweepInProgress = true;
    try {
      await _reporter.retryUnsent();
    } catch (e, stack) {
      // A failed sweep must not kill the reconnect subscription or periodic
      // fallback. The reporter keeps unsent rows for the next pass.
      _logger.w(
        'Security violation retry sweep failed',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _sweepInProgress = false;
    }
  }

  /// Stops all subscriptions/timers. The app lifecycle owner calls this on
  /// teardown; tests can also use it to avoid leaked connectivity listeners.
  Future<void> dispose() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
    _periodicTimer = null;
    await _canarySubscription?.cancel();
    _canarySubscription = null;
  }
}
