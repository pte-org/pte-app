import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'playback_level_meter.dart';

enum PteAudioPanelVariant { player, recorder }

/// Shared PTE-style chrome for an audio player or recorder.
///
/// This widget owns only the visual frame. Playback, recording, timers and
/// upload state stay in the feature widgets and are supplied as values/slots.
class PteAudioPanel extends StatelessWidget {
  const PteAudioPanel({
    super.key,
    required this.variant,
    required this.statusLabel,
    required this.progress,
    this.title,
    this.timeLabel,
    this.onPrimaryAction,
    this.onReplay,
    this.onStop,
    this.sideIndicator,
    this.trailingControl,
    this.showActivityMeter = false,
    this.activityMeterActive = true,
    this.maxWidth = AppDimensions.audioPanelMaxWidth,
    this.playing = true,
    this.isPreparingRecording = false,
  });

  final PteAudioPanelVariant variant;
  final String statusLabel;
  final double progress;
  final String? title;
  final String? timeLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onReplay;
  final VoidCallback? onStop;
  final Widget? sideIndicator;
  final Widget? trailingControl;
  final bool showActivityMeter;
  final bool activityMeterActive;
  final double maxWidth;
  final bool playing;
  final bool isPreparingRecording;

  bool get _isRecorder => variant == PteAudioPanelVariant.recorder;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle =
        title ??
        (_isRecorder
            ? AppStrings.audioRecorderTitle
            : AppStrings.audioPlayerTitle);
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final primaryIcon = onReplay != null
        ? (_isRecorder ? Icons.replay : Icons.play_arrow)
        : playing
        ? Icons.pause
        : Icons.play_arrow;
    final primaryTooltip = onReplay != null
        ? AppStrings.audioReplayTooltip
        : playing
        ? AppStrings.audioPauseTooltip
        : AppStrings.audioPlayTooltip;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          key: const ValueKey('pteAudioPanel'),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.audioPanelSurface,
            border: Border.all(color: AppColors.audioPanelBorder),
            borderRadius: BorderRadius.circular(AppDimensions.audioPanelRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: AppDimensions.audioPanelMainHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.spacingLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resolvedTitle,
                              style: AppTypography.audioPanelTitle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  statusLabel,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.audioPanelStatus
                                      .copyWith(
                                        color: AppColors.audioPanelStatus,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: AppDimensions.audioPanelRailWidth,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.audioPanelDivider),
                        ),
                      ),
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.spacingMd,
                      ),
                      alignment: Alignment.bottomCenter,
                      child:
                          sideIndicator ??
                          (showActivityMeter
                              ? PteAudioActivityMeter(
                                  active: activityMeterActive,
                                )
                              : const SizedBox.shrink()),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: AppDimensions.audioPanelControlsHeight,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.audioPanelDivider),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isRecorder || onStop != null) ...[
                        _AudioControlCell(
                          icon: _isRecorder && isPreparingRecording
                              ? Icons.fiber_manual_record
                              : Icons.stop,
                          color: _isRecorder && isPreparingRecording
                              ? AppColors.error
                              : null,
                          tooltip: _isRecorder && isPreparingRecording
                              ? AppStrings.audioRecordReadyTooltip
                              : _isRecorder
                              ? AppStrings.audioStopTooltip
                              : AppStrings.audioStopPlaybackTooltip,
                          onPressed: isPreparingRecording && _isRecorder
                              ? null
                              : onStop,
                        ),
                        const _AudioControlDivider(),
                      ],
                      _AudioControlCell(
                        icon: primaryIcon,
                        tooltip: primaryTooltip,
                        onPressed: onReplay ?? onPrimaryAction,
                      ),
                      const _AudioControlDivider(),
                      if (timeLabel != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingSm,
                          ),
                          child: Text(
                            timeLabel!,
                            style: AppTypography.audioPanelTime.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingSm,
                          ),
                          child: LinearProgressIndicator(
                            value: normalizedProgress,
                            minHeight: AppDimensions.audioPanelProgressHeight,
                            backgroundColor: AppColors.audioPanelTrack,
                            color: AppColors.audioPanelProgress,
                          ),
                        ),
                      ),
                      ?trailingControl,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared adapter for the real playback-level meter.
class PteAudioActivityMeter extends StatelessWidget {
  const PteAudioActivityMeter({super.key, this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return PlaybackLevelMeter(active: active);
  }
}

class _AudioControlCell extends StatelessWidget {
  const _AudioControlCell({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.audioPanelControlCellWidth,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        color: color ?? AppColors.audioPanelControl,
        disabledColor: color,
        icon: Icon(icon),
      ),
    );
  }
}

class _AudioControlDivider extends StatelessWidget {
  const _AudioControlDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: double.infinity,
      width: 1,
      child: ColoredBox(color: AppColors.audioPanelDivider),
    );
  }
}

String formatPteAudioDuration(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 359999);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
