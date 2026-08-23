import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';

/// Purely presentational "Recorded Answer" status card — takes an already
/// resolved [statusLabel] and [progress] as props, no BLoC/context reads of
/// its own, so it's trivially testable in isolation and reusable. Shared by
/// every auto-record speaking task's screen (Read Aloud, Repeat Sentence) —
/// not Read-Aloud-specific despite having originally lived under that name.
class RecordedAnswerStatusCard extends StatelessWidget {
  const RecordedAnswerStatusCard({super.key, required this.statusLabel, required this.progress});

  final String statusLabel;

  /// `0.0`–`1.0`, clamped by the caller — how much of the current
  /// prep/response window has elapsed.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.fillBlanksGapFilledBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              SpeakingWritingStrings.recordedAnswerCardTitle,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            SpeakingWritingStrings.recordingCurrentStatusLabel,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          Text(statusLabel, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppDimensions.spacingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.recordingProgressBarRadius),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: AppDimensions.recordingProgressBarHeight,
              backgroundColor: AppColors.onPrimary,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
