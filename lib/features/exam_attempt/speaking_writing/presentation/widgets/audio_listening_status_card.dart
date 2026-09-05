import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';

/// Purely presentational "listening" status card for audio-prompt speaking
/// tasks (Repeat Sentence today; the same shape would suit a future
/// audio-prompt task type like Retell Lecture, but this stays
/// Repeat-Sentence-only content-wise for now — no shared base until a 3rd
/// consumer needs it) — takes an already resolved [statusLabel] and
/// [progress] as props, no BLoC/context reads of its own.
///
/// The "Volume" row is entirely decorative — a static line with a
/// fixed-position dot, never driven by real audio amplitude. This app has
/// no audio-playback infrastructure (`just_audio` stays an unused pubspec
/// dependency, confirmed with the user) — do not wire this to
/// `AudioRecorderService` or any other real signal; it exists purely to
/// visually match the reference mockup.
class AudioListeningStatusCard extends StatelessWidget {
  const AudioListeningStatusCard({super.key, required this.statusLabel, required this.progress});

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
        border: Border.all(color: AppColors.fillBlanksGapEmptyBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SpeakingWritingStrings.recordingCurrentStatusLabel,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          Text(statusLabel, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              Text(
                SpeakingWritingStrings.audioListeningVolumeLabel,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              const Expanded(child: _DecorativeVolumeMeter()),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.recordingProgressBarRadius),
            // [progress] only ticks forward whenever the real audio
            // player's position stream happens to emit — on desktop that
            // can be coarser than once a second, so a bare
            // LinearProgressIndicator (which snaps instantly to a new
            // `value`, no interpolation of its own) visibly jumps in
            // uneven steps instead of gliding. TweenAnimationBuilder
            // smooths every jump into a short animation from wherever the
            // bar currently sits to the new target — its own current
            // animated value becomes the next tween's start automatically,
            // so this stays correct across any number of updates, not just
            // the first. The math underneath (position/duration) is
            // already an even, duration-proportional split — a 10s audio
            // advances ~10%/s, a 5s one ~20%/s — this only smooths how
            // that value is *rendered* between updates, it changes no
            // progress calculation (plans/phat-speaking-dynamic-prep-timing
            // Phase 5 walkthrough follow-up).
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

/// Static line + fixed-position dot — decorative only, see class doc above.
/// Never animates, never reads any data source.
class _DecorativeVolumeMeter extends StatelessWidget {
  const _DecorativeVolumeMeter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.audioListeningDotSize,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(height: AppDimensions.audioListeningMeterHeight, color: AppColors.fillBlanksGapEmptyBorder),
          const Align(alignment: Alignment(0.8, 0), child: _VolumeDot()),
        ],
      ),
    );
  }
}

class _VolumeDot extends StatelessWidget {
  const _VolumeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.audioListeningDotSize,
      height: AppDimensions.audioListeningDotSize,
      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
    );
  }
}
