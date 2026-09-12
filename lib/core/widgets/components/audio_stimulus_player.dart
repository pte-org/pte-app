import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

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
    return Container(
      width: 420,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPressed,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                color: AppColors.brandPrimary,
              ),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 6,
            backgroundColor: AppColors.divider,
            color: AppColors.brandPrimary,
          ),
        ],
      ),
    );
  }
}
