import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';

/// Blue-gradient banner with a star icon + task-type title (and an optional
/// how-to-answer [instruction] line underneath, matching the real PTE exam's
/// per-task instruction text), rendered as the first child inside a task
/// screen's [ExamScaffold.body] — an addition alongside the existing top
/// chrome, never a replacement for `ExamAppBar`'s timer/phase/force-submit
/// row. Shared across every skill (Reading, Listening, ...) so a future
/// visual restyle is a single-file edit instead of one per feature —
/// originally Reading-only (`ReadingTaskHeaderBanner`), promoted here on
/// request so Listening's screens use identical chrome.
class ExamTaskHeaderBanner extends StatelessWidget {
  const ExamTaskHeaderBanner({super.key, required this.title, this.instruction});

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
          vertical: AppDimensions.examHeaderBannerPaddingVertical,
          horizontal: AppDimensions.examHeaderBannerPaddingHorizontal,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.examHeaderGradientStart, AppColors.examHeaderGradientEnd]),
          borderRadius: BorderRadius.circular(AppDimensions.examHeaderBannerRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.star, color: AppColors.onPrimary, size: AppDimensions.examHeaderStarIconSize),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: AppDimensions.examHeaderTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (instruction != null && instruction!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.examHeaderInstructionSpacing),
                    Text(
                      instruction!,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: AppDimensions.examHeaderInstructionFontSize,
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
