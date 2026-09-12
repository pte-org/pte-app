import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/listening/constants/listening_strings.dart';

/// Pure presentational playback-status bar, reused by all 8 listening
/// screens. Deliberately takes a plain [hasFinishedPlaying] bool rather
/// than reading a `Cubit` directly — each task type has its own distinct
/// Cubit/State class, so a shared widget cannot import all of them without
/// repeating `McOptionList`'s coupling bug (phase-03 red-team finding).
/// Each screen's own `BlocBuilder` extracts the bool and passes it down.
/// No play/pause/replay control is exposed — playback starts automatically
/// when the screen's cubit is created (phase-01 Design Constraints).
class ListeningAudioBar extends StatelessWidget {
  const ListeningAudioBar({super.key, required this.hasFinishedPlaying});

  final bool hasFinishedPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMedium,
        vertical: AppDimensions.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: hasFinishedPlaying
            ? AppColors.successContainer
            : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            hasFinishedPlaying ? Icons.check_circle : Icons.volume_up,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Text(
            hasFinishedPlaying
                ? ListeningStrings.listeningAudioFinishedLabel
                : ListeningStrings.listeningAudioPlayingLabel,
          ),
        ],
      ),
    );
  }
}
