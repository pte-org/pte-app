import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
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
    final title = timeExpired
        ? AppStrings.sectionCompletedTimeUpTitle
        : AppStrings.sectionCompletedNaturalTitle;
    final message = timeExpired
        ? AppStrings.sectionCompletedTimeUpMessage
        : AppStrings.sectionCompletedNaturalMessage;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppDimensions.spacingMedium),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spacingMedium),
              Text('${AppStrings.examAttemptNumberLabel} $attemptNumber'),
              if (canRetry) ...[
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  '${AppStrings.examRetriesRemainingMessage}: $remainingRetries',
                ),
              ] else ...[
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  ExamAttemptStrings.retryLimitReachedMessage,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppDimensions.spacingMedium),
              PrimaryButton(
                label: AppStrings.sectionCompletedContinueButton,
                onPressed: onContinue,
              ),
              if (canRetry) ...[
                const SizedBox(height: AppDimensions.spacingSm),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(ExamAttemptStrings.attemptStartRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
