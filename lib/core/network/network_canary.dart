import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Emits once every time device connectivity transitions *into* a
/// connected state (not on every connectivity event — a lateral
/// transition like wifi-to-wifi would otherwise trigger a redundant flush
/// attempt). `connectivity_plus` reports OS-level connectivity, which can
/// be true while the exam API itself is unreachable (captive portal,
/// DNS-only outage) — this is a fast-path signal only; [SyncEngine]'s
/// mandatory periodic fallback tick is the correctness backstop for when
/// this canary is a false positive or is missed entirely (phase-02 Design
/// Constraints).
class NetworkCanary {
  NetworkCanary({Stream<List<ConnectivityResult>>? connectivityStream})
      : _connectivityStream = connectivityStream ?? Connectivity().onConnectivityChanged {
    _subscription = _connectivityStream.listen(_onConnectivityChanged);
  }

  final Stream<List<ConnectivityResult>> _connectivityStream;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  bool _wasConnected = false;

  Stream<void> get available => _controller.stream;

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isConnected = results.any((result) => result != ConnectivityResult.none);
    if (isConnected && !_wasConnected) {
      _controller.add(null);
    }
    _wasConnected = isConnected;
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
