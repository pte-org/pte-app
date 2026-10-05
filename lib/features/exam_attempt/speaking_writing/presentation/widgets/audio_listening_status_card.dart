import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';

/// Purely presentational "listening" status card for audio-prompt speaking
/// tasks (Repeat Sentence today; the same shape would suit a future
/// audio-prompt task type like Retell Lecture, but this stays
/// Repeat-Sentence-only content-wise for now — no shared base until a 3rd
/// consumer needs it) — takes an already resolved [statusLabel] and
/// [progress] as props, no BLoC/context reads of its own.
class AudioListeningStatusCard extends StatelessWidget {
  const AudioListeningStatusCard({
    super.key,
    required this.statusLabel,
    required this.progress,
  });

  final String statusLabel;

  /// `0.0`–`1.0`, clamped by the caller — how much of the current
  /// listening window has elapsed.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SpeakingWritingStrings.recordingCurrentStatusLabel,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          Text(
            statusLabel,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              Text(
                SpeakingWritingStrings.audioListeningVolumeLabel,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              const Expanded(child: _VolumeSlider()),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              AppDimensions.recordingProgressBarRadius,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: AppDimensions.recordingProgressBarHeight,
                  backgroundColor: AppColors.onPrimary,
                  color: AppColors.primary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Functional volume slider backed by the shared [VolumeService] from GetIt.
/// Falls back to a local one when none is registered (widget tests, previews),
/// same as `TestMicAndSoundScreen`.
class _VolumeSlider extends StatefulWidget {
  const _VolumeSlider();

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
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
    return ValueListenableBuilder<double>(
      valueListenable: _volumeService,
      builder: (context, volume, _) {
        return Slider(
          value: volume,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.primary,
          onChanged: (v) => _volumeService.value = v,
        );
      },
    );
  }
}
