import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';

class AudioStimulusPlayer extends StatelessWidget {
  const AudioStimulusPlayer({
    super.key,
    required this.label,
    this.progress = 0,
    this.onPressed,
    this.playing = false,
  });

  final String label;
  final double progress;
  final VoidCallback? onPressed;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return PteAudioPanel(
      variant: PteAudioPanelVariant.player,
      statusLabel: label,
      progress: progress,
      onPrimaryAction: onPressed,
      playing: playing,
      showActivityMeter: true,
      activityMeterActive: playing,
      trailingControl: Semantics(
        label: AppStrings.audioVolumeTooltip,
        button: true,
        child: Icon(Icons.volume_up, color: AppColors.audioPanelControl),
      ),
    );
  }
}
