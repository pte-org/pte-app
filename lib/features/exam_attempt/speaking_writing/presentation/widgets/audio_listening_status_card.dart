import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';
import 'package:pte_app/core/widgets/components/pte_volume_button.dart';
import 'package:pte_app/core/widgets/components/pte_status_audio_panel.dart';

/// PTE-style audio player used by Listening tasks and audio-prompt Speaking
/// tasks. Playback state is supplied by the caller; this widget owns only the
/// player chrome and the shared volume affordance.
class AudioListeningStatusCard extends StatefulWidget {
  const AudioListeningStatusCard({
    super.key,
    required this.statusLabel,
    required this.progress,
    this.timeLabel,
    this.playing = true,
    this.onPauseResume,
    this.onStop,
    this.onReplay,
    this.statusStyle = false,
  });

  final String statusLabel;
  final double progress;
  final String? timeLabel;
  final bool playing;
  final VoidCallback? onPauseResume;
  final VoidCallback? onStop;
  final VoidCallback? onReplay;
  final bool statusStyle;

  @override
  State<AudioListeningStatusCard> createState() =>
      _AudioListeningStatusCardState();
}

class _AudioListeningStatusCardState extends State<AudioListeningStatusCard> {
  late final VolumeService _volumeService;
  late final bool _ownsVolumeService;

  @override
  void initState() {
    super.initState();
    _ownsVolumeService = !GetIt.instance.isRegistered<VolumeService>();
    _volumeService = _ownsVolumeService
        ? VolumeService()
        : GetIt.instance<VolumeService>();
  }

  @override
  void dispose() {
    if (_ownsVolumeService) _volumeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statusStyle) {
      return PteStatusAudioPanel(
        statusLabel: widget.statusLabel,
        progress: widget.progress,
        volumeControl: ValueListenableBuilder<double>(
          valueListenable: _volumeService,
          builder: (context, volume, _) => Slider(
            value: volume,
            onChanged: (value) => _volumeService.value = value,
          ),
        ),
      );
    }
    return PteAudioPanel(
      variant: PteAudioPanelVariant.player,
      statusLabel: widget.statusLabel,
      progress: widget.progress,
      timeLabel: widget.timeLabel,
      playing: widget.playing,
      onPrimaryAction: widget.onPauseResume,
      onStop: widget.onStop,
      onReplay: widget.onReplay,
      showActivityMeter: true,
      activityMeterActive: widget.playing && widget.progress < 1.0,
      trailingControl: PteVolumeButton(volumeService: _volumeService),
    );
  }
}
