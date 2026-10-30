import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pte_audio_level_meter.dart';

/// Live peak of this application's Windows playback session, sampled without
/// capturing the microphone or mixing in sound from other applications.
class PlaybackLevelMeter extends StatefulWidget {
  const PlaybackLevelMeter({super.key, required this.active});
  final bool active;

  @override
  State<PlaybackLevelMeter> createState() => _PlaybackLevelMeterState();
}

class _PlaybackLevelMeterState extends State<PlaybackLevelMeter> {
  static const _channel = MethodChannel('pte/audio_levels');
  Timer? _timer;
  double _level = 0;
  bool _sampling = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(PlaybackLevelMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _restart();
  }

  void _restart() {
    _timer?.cancel();
    _generation++;
    _level = 0;
    if (!widget.active || !Platform.isWindows) return;
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) => _sample());
    unawaited(_sample());
  }

  Future<void> _sample() async {
    if (_sampling) return;
    _sampling = true;
    final generation = _generation;
    try {
      final peak = await _channel.invokeMethod<double>('getPlaybackLevel') ?? 0;
      if (!mounted || generation != _generation || !widget.active) return;
      // Fast attack, short decay; zero output still falls back to silence.
      final normalized = peak.isFinite ? peak.clamp(0.0, 1.0) : 0.0;
      final next = normalized > _level ? normalized : _level * 0.45;
      final level = next < 0.005 ? 0.0 : next;
      if (level != _level) setState(() => _level = level);
    } on PlatformException {
      // Device changes may temporarily remove the render endpoint.
    } on MissingPluginException {
      _timer?.cancel();
    } finally {
      _sampling = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PteAudioLevelMeter(level: _level);
}
