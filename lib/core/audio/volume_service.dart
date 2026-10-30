import 'package:flutter/foundation.dart';

/// Shared playback volume (0.0–1.0) persisted for the lifetime of the app
/// process. Audio player impls subscribe to this notifier and forward volume
/// changes to their underlying `AudioPlayer.setVolume()` call. UI widgets
/// read it via `ValueListenableBuilder` without needing a cubit.
class VolumeService extends ValueNotifier<double> {
  VolumeService() : super(1.0);

  double _lastAudibleVolume = 1.0;

  @override
  set value(double newValue) {
    final normalized = newValue.isFinite ? newValue.clamp(0.0, 1.0) : 0.0;
    if (normalized > 0) _lastAudibleVolume = normalized;
    super.value = normalized;
  }

  void toggleMute() => value = value == 0 ? _lastAudibleVolume : 0;
}
