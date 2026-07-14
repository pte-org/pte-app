import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';

class SpeakingProgressDots extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final ValueChanged<int>? onDotSelected;

  const SpeakingProgressDots({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    this.onDotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalCount, _buildDot),
    );
  }

  Widget _buildDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.speakingDotGap,
      ),
      child: GestureDetector(
        onTap: onDotSelected == null ? null : () => onDotSelected!(index),
        child: Container(
          width: AppDimensions.speakingDotSize,
          height: AppDimensions.speakingDotSize,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? AppColors.textMedium
                : AppColors.backgroundWhite,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.dividerGray),
          ),
        ),
      ),
    );
  }
}
