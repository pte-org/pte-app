import '../timer/timer_service.dart';

/// Treats a successful timer-sync poll (Phase 4) as the truth signal for
/// "we are online," rather than an OS-level connectivity event
/// (`connectivity_plus` alone) — a captive portal or DNS-only outage can
/// report "connected" while the exam API itself is unreachable. This is
/// the sole source of "network available" truth the sync engine acts on.
class NetworkCanary {
  NetworkCanary({Stream<void>? availableStream, TimerService? timerService})
    : available = availableStream ?? timerService!.ticks.map((_) {});

  /// Emits once for every successful timer-sync response. [TimerService]
  /// only adds to its `ticks` stream from `reconcileFromServer`, which is
  /// reachable only after a successful poll — failed polls never reach it,
  /// so a failed poll never produces an "available" event here.
  final Stream<void> available;
}
