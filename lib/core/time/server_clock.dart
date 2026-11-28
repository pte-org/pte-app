/// Server-time-anchored clock that advances only via monotonic elapsed.
///
/// The device wall clock can jump (NTP resync, manual change), causing
/// `DateTime.now()` to become unreliable for exam timing. [ServerClock] solves
/// this by anchoring once to a server-provided time (e.g. from an HTTP `Date`
/// header or a `serverTime` field in an API response) and advancing that
/// anchor only by monotonic elapsed duration, never touching the wall clock
/// again.
class ServerClock {
  /// Creates a [ServerClock].
  ///
  /// - [wallClock]: Optional function that returns the current wall-clock time.
  ///   Defaults to `DateTime.now`. Used only before the first [syncWith] call.
  /// - [monotonicElapsed]: Optional function that returns monotonic elapsed time.
  ///   Defaults to a `Stopwatch`-backed implementation. Used to advance the
  ///   anchor after the first [syncWith] call.
  ServerClock({
    DateTime Function()? wallClock,
    Duration Function()? monotonicElapsed,
  })  : _wallClock = wallClock ?? (() => DateTime.now()),
        _monotonicElapsed = monotonicElapsed ?? _defaultMonotonicElapsed;

  static final _stopwatch = Stopwatch()..start();

  static Duration _defaultMonotonicElapsed() => _stopwatch.elapsed;

  final DateTime Function() _wallClock;
  final Duration Function() _monotonicElapsed;

  DateTime? _syncedAnchor;
  Duration? _monotonicAtSync;

  /// The difference between server time and device wall clock at the last
  /// [syncWith] call. Zero before the first sync.
  Duration get offset {
    if (_syncedAnchor == null) return Duration.zero;
    return _syncedAnchor!.difference(_wallClock());
  }

  /// True after the first [syncWith] call.
  bool get isSynced => _syncedAnchor != null;

  /// Re-anchoring on every response would make the timer jump back: the HTTP
  /// `Date` header is truncated to whole seconds and arrives after network
  /// latency. Samples closer than this to the current reading are ignored.
  static const Duration resyncTolerance = Duration(seconds: 2);

  /// Syncs to a server-provided time (e.g. from HTTP `Date` header).
  /// After this call, [now] advances only via [_monotonicElapsed].
  void syncWith(DateTime serverTime) {
    if (_syncedAnchor != null &&
        serverTime.difference(now()).abs() <= resyncTolerance) {
      return;
    }
    _syncedAnchor = serverTime;
    _monotonicAtSync = _monotonicElapsed();
  }

  /// Returns the current time: either the device wall clock (before the first
  /// [syncWith]), or the synced anchor advanced by monotonic elapsed.
  DateTime now() {
    if (_syncedAnchor == null) {
      return _wallClock();
    }
    final monotonicNow = _monotonicElapsed();
    final monotonicAtSync = _monotonicAtSync!;
    final elapsed = monotonicNow.inMicroseconds - monotonicAtSync.inMicroseconds;
    return _syncedAnchor!.add(Duration(microseconds: elapsed));
  }
}
