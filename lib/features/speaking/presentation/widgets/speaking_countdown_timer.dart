import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

class SpeakingCountdownTimer extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;
  final String label;

  const SpeakingCountdownTimer({
    super.key,
    required this.timeRemaining,
    required this.totalTime,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalTime > 0 ? timeRemaining / totalTime : 0.0;
    final bool isWarning = timeRemaining <= 5 && timeRemaining > 0;
    final Color timerColor = isWarning ? Colors.red : AppColors.primaryLime;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMedium,
        vertical: AppDimensions.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border.all(color: AppColors.loginPanelBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.loginLabel.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${timeRemaining}s',
                style: AppTextStyles.loginTitle.copyWith(
                  fontSize: 16,
                  color: timerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.dividerGray,
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
