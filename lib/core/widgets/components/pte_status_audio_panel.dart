import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';

/// Status-style media chrome used by Group Discussion and Situation tasks.
/// Playback, recording and timing remain owned by the calling feature.
class PteStatusAudioPanel extends StatelessWidget {
  const PteStatusAudioPanel({
    super.key,
    required this.statusLabel,
    required this.progress,
    this.isRecorder = false,
    this.volumeControl,
  });

  final String statusLabel;
  final double progress;
  final bool isRecorder;
  final Widget? volumeControl;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey(isRecorder ? 'pteStatusRecorder' : 'pteStatusPlayer'),
    width: double.infinity,
    constraints: const BoxConstraints(
      minHeight: AppDimensions.statusAudioPanelMinHeight,
    ),
    padding: const EdgeInsets.all(AppDimensions.spacingMd),
    decoration: BoxDecoration(
      color: isRecorder ? AppColors.surfaceSubtle : AppColors.audioPanelSurface,
      border: Border.all(color: AppColors.audioPanelBorder),
      borderRadius: BorderRadius.circular(AppDimensions.audioPanelRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRecorder) ...[
          Text(
            AppStrings.recordedAnswerTitle,
            textAlign: TextAlign.center,
            style: AppTypography.audioPanelTitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          Text(
            AppStrings.audioCurrentStatusLabel,
            style: AppTypography.audioPanelStatus,
          ),
          Text(statusLabel, style: AppTypography.audioPanelStatus),
        ] else ...[
          Text(
            '${AppStrings.audioStatusLabel} $statusLabel',
            style: AppTypography.audioPanelStatus,
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          Row(
            children: [
              Text(
                AppStrings.audioVolumeTooltip,
                style: AppTypography.audioPanelStatus,
              ),
              Expanded(child: volumeControl ?? const SizedBox.shrink()),
            ],
          ),
        ],
        const SizedBox(height: AppDimensions.spacingMd),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: AppDimensions.statusAudioProgressHeight,
          color: AppColors.success,
          backgroundColor: AppColors.audioPanelTrack,
        ),
      ],
    ),
  );
}

/// Keeps both surfaces mounted, including the completed prompt player.
class PteStatusAudioPair extends StatelessWidget {
  const PteStatusAudioPair({
    super.key,
    required this.player,
    required this.recorder,
  });
  final Widget player;
  final Widget recorder;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppDimensions.statusAudioPanelMaxWidth,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          player,
          const SizedBox(height: AppDimensions.spacingLg),
          recorder,
        ],
      ),
    ),
  );
}
