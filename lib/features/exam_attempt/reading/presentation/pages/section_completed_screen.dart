import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/core/widgets/secondary_button.dart';
import 'package:pte_app/core/widgets/status_screen.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Completion screen shown after `AttemptCompleted`, before the
/// report (Screen 7 of the Reading flow) — [timeExpired] picks between the
/// "Time is up" and "Reading Section Completed" wording (`AttemptCompleted
/// .timeExpired`). [onContinue] is an explicit tap rather than a timed
/// auto-transition, to keep this screen (and its tests) deterministic.
class SectionCompletedScreen extends StatelessWidget {
  const SectionCompletedScreen({
    super.key,
    required this.timeExpired,
    required this.attemptNumber,
    required this.remainingRetries,
    required this.canRetry,
    required this.onContinue,
    required this.onRetry,
  });

  final bool timeExpired;
  final int attemptNumber;
  final int remainingRetries;
  final bool canRetry;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      icon: timeExpired ? Icons.timer_off_outlined : Icons.check_circle_outline,
      title: timeExpired
          ? AppStrings.sectionCompletedTimeUpTitle
          : AppStrings.sectionCompletedNaturalTitle,
      message: timeExpired
          ? AppStrings.sectionCompletedTimeUpMessage
          : AppStrings.sectionCompletedNaturalMessage,
      children: [
        _AttemptSummary(
          attemptNumber: attemptNumber,
          remainingRetries: remainingRetries,
          canRetry: canRetry,
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        PrimaryButton(
          label: AppStrings.sectionCompletedContinueButton,
          onPressed: onContinue,
        ),
        if (canRetry) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          SecondaryButton(
            label: ExamAttemptStrings.attemptStartRetry,
            onPressed: onRetry,
          ),
        ],
      ],
    );
  }
}

class _AttemptSummary extends StatelessWidget {
  const _AttemptSummary({
    required this.attemptNumber,
    required this.remainingRetries,
    required this.canRetry,
  });

  final int attemptNumber;
  final int remainingRetries;
  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.radiusDefault),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            label: AppStrings.examAttemptNumberLabel,
            value: '$attemptNumber',
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          if (canRetry)
            _SummaryRow(
              label: AppStrings.examRetriesRemainingMessage,
              value: '$remainingRetries',
            )
          else
            Text(
              ExamAttemptStrings.retryLimitReachedMessage,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
