import 'package:flutter/foundation.dart';

/// Shared playback volume (0.0–1.0) persisted for the lifetime of the app
/// process. Audio player impls subscribe to this notifier and forward volume
/// changes to their underlying `AudioPlayer.setVolume()` call. UI widgets
/// read it via `ValueListenableBuilder` without needing a cubit.
class VolumeService extends ValueNotifier<double> {
  VolumeService() : super(1.0);
}
