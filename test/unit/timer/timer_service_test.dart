import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aptis_app/core/network/api_client.dart';
import 'package:aptis_app/core/network/models/timer_sync_response.dart';
import 'package:aptis_app/core/timer/timer_service.dart';

/// Hand-written fake `Stopwatch` (no mocking package added) — only
/// advances when explicitly told to, so tests control elapsed time
/// directly instead of waiting on real wall-clock time.
class _FakeStopwatch implements Stopwatch {
  int _elapsedMs = 0;
  bool _running = false;

  void advance(int milliseconds) {
    if (_running) _elapsedMs += milliseconds;
  }

  @override
  void start() => _running = true;

  @override
  void stop() => _running = false;

  @override
  void reset() => _elapsedMs = 0;

  @override
  int get elapsedTicks => _elapsedMs;

  @override
  Duration get elapsed => Duration(milliseconds: _elapsedMs);

  @override
  int get elapsedMicroseconds => _elapsedMs * 1000;

  @override
  int get elapsedMilliseconds => _elapsedMs;

  @override
  bool get isRunning => _running;

  @override
  int get frequency => 1000;
}

/// Hand-written fake `ApiClient` — overrides only [syncTimer], the one
/// method `TimerService` calls, routing it through a per-test handler.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this._handler) : super(Dio());

  final Future<TimerSyncResponse> Function(String attemptId) _handler;

  @override
  Future<TimerSyncResponse> syncTimer(String attemptId) => _handler(attemptId);
}

void main() {
  group('TimerService', () {
    test(
      'startCountdown(60) then advancing 5000ms gives elapsed=5 and countdown=55',
      () {
        final stopwatch = _FakeStopwatch();
        final service = TimerService(stopwatch: stopwatch);

        service.startCountdown(60);
        stopwatch.advance(5000);

        expect(service.getElapsedSeconds(), 5);
        expect(60 - service.getElapsedSeconds(), 55);
      },
    );

    test(
      'countdown moves by exactly the Stopwatch delta, simulating a system clock jump having zero effect',
      () {
        final stopwatch = _FakeStopwatch();
        final service = TimerService(stopwatch: stopwatch);
        service.startCountdown(3600);

        final before = service.currentTimeRemaining;
        stopwatch.advance(5000);
        final after = service.currentTimeRemaining;

        expect(before - after, 5);
      },
    );

    test(
      'reconcileFromServer resets the stopwatch and emits a tick immediately',
      () async {
        final stopwatch = _FakeStopwatch();
        final service = TimerService(stopwatch: stopwatch);
        service.startCountdown(60);
        stopwatch.advance(10000);

        final tickFuture = service.ticks.first;
        service.reconcileFromServer(30);

        expect(service.timeRemainingSeconds, 30);
        expect(stopwatch.elapsedMilliseconds, 0);
        expect(await tickFuture, 30);

        service.dispose();
      },
    );

    test(
      'startPollingTimer: success reconciles, failure does not reconcile but still reschedules',
      () async {
        var callCount = 0;
        final fakeApiClient = _FakeApiClient((attemptId) async {
          callCount++;
          if (callCount == 1) {
            return TimerSyncResponse(
              timeRemaining: const Duration(seconds: 42),
              serverTimestamp: DateTime.utc(2026),
            );
          }
          throw Exception('network error');
        });

        void Function()? scheduledCallback;
        final service = TimerService(
          apiClient: fakeApiClient,
          scheduler: (duration, callback) {
            scheduledCallback = callback;
            return Timer(const Duration(days: 1), () {});
          },
        );

        await service.startPollingTimer('attempt-1');
        expect(service.timeRemainingSeconds, 42);
        expect(scheduledCallback, isNotNull);

        final callbackAfterSuccess = scheduledCallback;
        callbackAfterSuccess!();
        await Future<void>.delayed(Duration.zero);

        expect(service.timeRemainingSeconds, 42);
        expect(scheduledCallback, isNotNull);

        service.dispose();
      },
    );

    test('scheduled poll interval is <=10s', () async {
      final fakeApiClient = _FakeApiClient(
        (attemptId) async => TimerSyncResponse(
          timeRemaining: const Duration(seconds: 10),
          serverTimestamp: DateTime.utc(2026),
        ),
      );

      Duration? capturedInterval;
      final service = TimerService(
        apiClient: fakeApiClient,
        scheduler: (duration, callback) {
          capturedInterval = duration;
          return Timer(const Duration(days: 1), () {});
        },
      );

      await service.startPollingTimer('attempt-1');

      expect(capturedInterval, isNotNull);
      expect(capturedInterval!.inSeconds, lessThanOrEqualTo(10));

      service.dispose();
    });
  });
}
