import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Blue-gradient banner with a star icon + task-type title (and an optional
/// how-to-answer [instruction] line underneath, matching the real PTE exam's
/// per-task instruction text), rendered as the first child inside a reading
/// screen's [ExamScaffold.body] — an addition alongside the existing top
/// chrome, never a replacement for `ExamAppBar`'s timer/phase/force-submit
/// row.
class ReadingTaskHeaderBanner extends StatelessWidget {
  const ReadingTaskHeaderBanner({
    super.key,
    required this.title,
    this.instruction,
  });

  final String title;
  final String? instruction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.readingContentCardMargin,
        AppDimensions.readingContentCardMargin,
        AppDimensions.readingContentCardMargin,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.readingHeaderBannerPaddingVertical,
          horizontal: AppDimensions.readingHeaderBannerPaddingHorizontal,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.readingHeaderGradientStart,
              AppColors.readingHeaderGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(
            AppDimensions.readingHeaderBannerRadius,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.star,
              color: AppColors.onPrimary,
              size: AppDimensions.readingHeaderStarIconSize,
            ),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: AppDimensions.readingHeaderTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (instruction != null && instruction!.isNotEmpty) ...[
                    const SizedBox(
                      height: AppDimensions.readingHeaderInstructionSpacing,
                    ),
                    Text(
                      instruction!,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize:
                            AppDimensions.readingHeaderInstructionFontSize,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
