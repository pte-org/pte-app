import 'dart:async';

import '../network/api_client.dart';

/// Schedules a one-shot poll callback. Production uses [Timer.new];
/// tests inject a fake that captures the [Duration] argument and lets
/// the test manually invoke the callback instead of waiting real time.
typedef TimerScheduler =
    Timer Function(Duration duration, void Function() callback);

/// Anchors the exam countdown to the last server-provided `time_remaining`
/// plus elapsed monotonic [Stopwatch] ticks. Never reads `DateTime.now()`
/// for countdown arithmetic — a system clock change mid-exam must have
/// zero effect on the displayed value (FR-04).
class TimerService {
  TimerService({
    Stopwatch? stopwatch,
    ApiClient? apiClient,
    TimerScheduler? scheduler,
  }) : _stopwatch = stopwatch ?? Stopwatch(),
       _apiClient = apiClient,
       _scheduler = scheduler ?? Timer.new;

  final Stopwatch _stopwatch;
  final ApiClient? _apiClient;
  final TimerScheduler _scheduler;
  final StreamController<int> _tickController =
      StreamController<int>.broadcast();

  int _timeRemainingSeconds = 0;
  Timer? _pollTimer;

  /// Emits the current countdown (seconds) on every server reconciliation.
  Stream<int> get ticks => _tickController.stream;

  int get timeRemainingSeconds => _timeRemainingSeconds;

  void startCountdown(int initialTimeRemainingSeconds) {
    _timeRemainingSeconds = initialTimeRemainingSeconds;
    _stopwatch
      ..reset()
      ..start();
  }

  double getElapsedSeconds() => _stopwatch.elapsedMilliseconds / 1000;

  int get currentTimeRemaining {
    final remaining = _timeRemainingSeconds - getElapsedSeconds();
    return remaining <= 0 ? 0 : remaining.round();
  }

  void reconcileFromServer(int newTimeRemainingSeconds) {
    _timeRemainingSeconds = newTimeRemainingSeconds;
    _stopwatch
      ..reset()
      ..start();
    _tickController.add(currentTimeRemaining);
  }

  Future<void> startPollingTimer(
    String attemptId, {
    Duration interval = const Duration(seconds: 10),
  }) {
    return _poll(attemptId, interval);
  }

  Future<void> _poll(String attemptId, Duration interval) async {
    try {
      final response = await _apiClient!.syncTimer(attemptId);
      reconcileFromServer(response.timeRemaining.inSeconds);
    } catch (_) {
      // Silent retry — connectivity state is the sync engine/Bloc's concern,
      // not this loop's. Never block on a single failed sync.
    }
    _pollTimer = _scheduler(interval, () {
      unawaited(_poll(attemptId, interval));
    });
  }

  void dispose() {
    _pollTimer?.cancel();
    unawaited(_tickController.close());
  }
}
