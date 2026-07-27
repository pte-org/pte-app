/// Tracks a single client-wide cooldown window after a 429, shared by
/// [SyncEngine] and `MediaUploadCoordinator` — each holds its own instance
/// (the cooldown is per-engine, not per-row), but both use this one class
/// rather than duplicating the deadline/exponential-growth bookkeeping
/// (phase-07 Design Constraints). Not a `Timer` itself: callers poll
/// [isActive] on their own existing canary/periodic tick rather than this
/// class scheduling anything on its own.
class RateLimitBackoff {
  RateLimitBackoff({
    Duration baseInterval = const Duration(seconds: 1),
    Duration maxInterval = const Duration(seconds: 32),
    DateTime Function()? now,
  }) : _baseInterval = baseInterval,
       _maxInterval = maxInterval,
       _now = now ?? DateTime.now;

  final Duration _baseInterval;
  final Duration _maxInterval;
  final DateTime Function() _now;

  DateTime? _cooldownUntil;
  Duration _lastInterval = Duration.zero;

  /// Whether callers should currently skip flush/upload attempts entirely.
  bool get isActive {
    final until = _cooldownUntil;
    return until != null && _now().isBefore(until);
  }

  /// Records a 429. [retryAfter], when the server supplied one, is used
  /// verbatim; otherwise the cooldown doubles from the last interval used
  /// (capped at [_maxInterval]), starting from [_baseInterval].
  void registerRateLimited({Duration? retryAfter}) {
    final interval = retryAfter ?? _nextInterval();
    _cooldownUntil = _now().add(interval);
  }

  Duration _nextInterval() {
    final next = _lastInterval == Duration.zero ? _baseInterval : _lastInterval * 2;
    _lastInterval = next > _maxInterval ? _maxInterval : next;
    return _lastInterval;
  }

  /// Called after the next successful flush/upload step — clears the
  /// cooldown and resets exponential growth back to [_baseInterval].
  void reset() {
    _cooldownUntil = null;
    _lastInterval = Duration.zero;
  }
}
