import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import 'countdown_timer.dart';

/// Top-of-task title + instruction + countdown row, used by every writing
/// screen as the first child inside the existing `ExamScaffold.body`. Kept
/// distinct from `ExamAppBar` so the screen still renders its phase /
/// total-tasks / force-submit chrome untouched.
class WritingTaskHeader extends StatelessWidget {
  const WritingTaskHeader({
    super.key,
    required this.title,
    required this.instruction,
    required this.totalSeconds,
    this.onTimeExpired,
  });

  final String title;
  final String instruction;
  final int totalSeconds;
  final VoidCallback? onTimeExpired;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.writingHeaderPaddingHorizontal,
        vertical: AppDimensions.writingHeaderPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: AppColors.passagePanelBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDimensions.readingHeaderTitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              CountdownTimer(totalSeconds: totalSeconds, onExpired: onTimeExpired),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(instruction, style: const TextStyle(color: AppColors.textPrimary, height: 1.3)),
        ],
      ),
    );
  }
}
