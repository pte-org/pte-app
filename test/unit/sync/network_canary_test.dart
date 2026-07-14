import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aptis_app/core/network/api_client.dart';
import 'package:aptis_app/core/network/models/timer_sync_response.dart';
import 'package:aptis_app/core/sync/network_canary.dart';
import 'package:aptis_app/core/timer/timer_service.dart';

/// Hand-written fake `ApiClient` — overrides only [syncTimer], matching
/// the pattern used in Phase 4's `timer_service_test.dart`.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this._handler) : super(Dio());

  final Future<TimerSyncResponse> Function(String attemptId) _handler;

  @override
  Future<TimerSyncResponse> syncTimer(String attemptId) => _handler(attemptId);
}

void main() {
  group('NetworkCanary', () {
    test(
      'emits available only after a successful timer-sync poll, never on a failed one',
      () async {
        var callCount = 0;
        final fakeApiClient = _FakeApiClient((attemptId) async {
          callCount++;
          if (callCount == 1) {
            return TimerSyncResponse(
              timeRemaining: const Duration(seconds: 60),
              serverTimestamp: DateTime.utc(2026),
            );
          }
          throw Exception('simulated timeout');
        });

        void Function()? scheduledCallback;
        final timerService = TimerService(
          apiClient: fakeApiClient,
          scheduler: (duration, callback) {
            scheduledCallback = callback;
            return Timer(const Duration(days: 1), () {});
          },
        );
        final canary = NetworkCanary(timerService: timerService);

        var availableCount = 0;
        final subscription = canary.available.listen((_) => availableCount++);

        await timerService.startPollingTimer('attempt-1');
        await Future<void>.delayed(Duration.zero);
        expect(availableCount, 1);

        scheduledCallback!();
        await Future<void>.delayed(Duration.zero);
        expect(availableCount, 1);

        await subscription.cancel();
        timerService.dispose();
      },
    );
  });
}
