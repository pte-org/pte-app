import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/domain/heartbeat_service.dart';

class _MockApiClient extends Mock implements ApiClient {}

Response<void> _okResponse() => Response<void>(requestOptions: RequestOptions(path: '/x'), statusCode: 200);

/// Mirrors `SyncEngineTest`'s fake-periodic-timer-factory convention —
/// captures the callback so a test can drive it manually instead of
/// waiting on the real 15s interval, and returns a long-lived, never-really-
/// firing `Timer` so `Timer.cancel()` calls remain harmless no-ops.
class _CapturingPeriodicFactory {
  final List<Duration> periods = [];
  void Function(Timer)? callback;

  Timer call(Duration period, void Function(Timer) cb) {
    periods.add(period);
    callback = cb;
    return Timer(const Duration(days: 999), () {});
  }
}

void main() {
  late _MockApiClient apiClient;

  setUp(() {
    apiClient = _MockApiClient();
    when(() => apiClient.sendHeartbeat(any())).thenAnswer((_) async => _okResponse());
  });

  test('start() pings immediately, synchronously scheduling the periodic timer at the configured interval', () async {
    final factory = _CapturingPeriodicFactory();
    final service = HeartbeatService(apiClient: apiClient, createPeriodicTimer: factory.call);

    service.start('attempt-1');
    await Future<void>.delayed(Duration.zero);

    verify(() => apiClient.sendHeartbeat('attempt-1')).called(1);
    expect(factory.periods, [const Duration(seconds: 15)]);
  });

  test('a custom interval is honored', () {
    final factory = _CapturingPeriodicFactory();
    final service = HeartbeatService(
      apiClient: apiClient,
      interval: const Duration(seconds: 5),
      createPeriodicTimer: factory.call,
    );

    service.start('attempt-1');

    expect(factory.periods, [const Duration(seconds: 5)]);
  });

  test('the periodic callback pings again on every fire', () async {
    final factory = _CapturingPeriodicFactory();
    final service = HeartbeatService(apiClient: apiClient, createPeriodicTimer: factory.call);
    service.start('attempt-1');
    await Future<void>.delayed(Duration.zero);

    factory.callback!(Timer(Duration.zero, () {}));
    await Future<void>.delayed(Duration.zero);
    factory.callback!(Timer(Duration.zero, () {}));
    await Future<void>.delayed(Duration.zero);

    verify(() => apiClient.sendHeartbeat('attempt-1')).called(3); // initial + 2 periodic fires
  });

  test(
    'calling start() again for the SAME attempt is a no-op — does not restart the periodic chain '
    '(client-side-exam-timer Phase 4: must stay independent of TimerService/SyncEngine\'s task-scoped calls)',
    () async {
      final factory = _CapturingPeriodicFactory();
      final service = HeartbeatService(apiClient: apiClient, createPeriodicTimer: factory.call);

      service.start('attempt-1');
      await Future<void>.delayed(Duration.zero);
      service.start('attempt-1'); // e.g. every task transition calling this again
      service.start('attempt-1');
      await Future<void>.delayed(Duration.zero);

      expect(factory.periods, hasLength(1)); // only one periodic chain was ever created
      verify(() => apiClient.sendHeartbeat('attempt-1')).called(1); // only the first immediate ping fired
    },
  );

  test('calling start() for a DIFFERENT attempt supersedes the prior chain', () async {
    final factory = _CapturingPeriodicFactory();
    final service = HeartbeatService(apiClient: apiClient, createPeriodicTimer: factory.call);

    service.start('attempt-1');
    await Future<void>.delayed(Duration.zero);
    service.start('attempt-2');
    await Future<void>.delayed(Duration.zero);

    expect(factory.periods, hasLength(2));
    verify(() => apiClient.sendHeartbeat('attempt-1')).called(1);
    verify(() => apiClient.sendHeartbeat('attempt-2')).called(1);
  });

  test('stop() clears the running-attempt guard, so a later start() for the same id works again (not stuck no-op)', () async {
    final factory = _CapturingPeriodicFactory();
    final service = HeartbeatService(apiClient: apiClient, createPeriodicTimer: factory.call);

    service.start('attempt-1');
    await Future<void>.delayed(Duration.zero);
    service.stop();
    service.start('attempt-1');
    await Future<void>.delayed(Duration.zero);

    expect(factory.periods, hasLength(2)); // a genuinely new chain, not suppressed by the old guard
    verify(() => apiClient.sendHeartbeat('attempt-1')).called(2);
  });

  test('a failed heartbeat is swallowed — never thrown, never surfaced, and the chain keeps running', () async {
    final factory = _CapturingPeriodicFactory();
    when(() => apiClient.sendHeartbeat(any())).thenThrow(Exception('network blip'));
    final service = HeartbeatService(apiClient: apiClient, createPeriodicTimer: factory.call);

    expect(() => service.start('attempt-1'), returnsNormally);
    await Future<void>.delayed(Duration.zero);

    expect(() => factory.callback!(Timer(Duration.zero, () {})), returnsNormally);
    await Future<void>.delayed(Duration.zero);

    verify(() => apiClient.sendHeartbeat('attempt-1')).called(2);
  });

  test('dispose() stops the chain', () async {
    final factory = _CapturingPeriodicFactory();
    final service = HeartbeatService(apiClient: apiClient, createPeriodicTimer: factory.call);
    service.start('attempt-1');
    await Future<void>.delayed(Duration.zero);

    expect(() => service.dispose(), returnsNormally);
    service.start('attempt-1'); // must work again after dispose, same as after stop()

    expect(factory.periods, hasLength(2));
  });
}
