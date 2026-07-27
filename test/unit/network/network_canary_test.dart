import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/network/network_canary.dart';

void main() {
  test('emits on a transition into a connected state', () async {
    final controller = StreamController<List<ConnectivityResult>>();
    final canary = NetworkCanary(connectivityStream: controller.stream);
    final events = <void>[];
    final subscription = canary.available.listen(events.add);

    controller.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));

    await subscription.cancel();
    await canary.dispose();
    await controller.close();
  });

  test('does not emit on a lateral transition (still connected, different network type)', () async {
    final controller = StreamController<List<ConnectivityResult>>();
    final canary = NetworkCanary(connectivityStream: controller.stream);
    final events = <void>[];
    final subscription = canary.available.listen(events.add);

    controller.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    controller.add([ConnectivityResult.mobile]); // still connected, lateral transition
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1)); // only the initial none->connected transition

    await subscription.cancel();
    await canary.dispose();
    await controller.close();
  });

  test('does not emit when transitioning into a disconnected state, and re-emits on reconnect', () async {
    final controller = StreamController<List<ConnectivityResult>>();
    final canary = NetworkCanary(connectivityStream: controller.stream);
    final events = <void>[];
    final subscription = canary.available.listen(events.add);

    controller.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    controller.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    controller.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(2)); // initial connect + reconnect, never the disconnect

    await subscription.cancel();
    await canary.dispose();
    await controller.close();
  });
}
