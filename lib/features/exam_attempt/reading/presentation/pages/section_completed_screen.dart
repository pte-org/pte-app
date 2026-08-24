import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/primary_button.dart';

/// Transitional screen shown right after `AttemptCompleted`, before the
/// report (Screen 7 of the Reading flow) — [timeExpired] picks between the
/// "Time is up" and "Reading Section Completed" wording (`AttemptCompleted
/// .timeExpired`). [onContinue] is an explicit tap rather than a timed
/// auto-transition, to keep this screen (and its tests) deterministic.
class SectionCompletedScreen extends StatelessWidget {
  const SectionCompletedScreen({super.key, required this.timeExpired, required this.onContinue});

  final bool timeExpired;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final title = timeExpired ? AppStrings.sectionCompletedTimeUpTitle : AppStrings.sectionCompletedNaturalTitle;
    final message = timeExpired ? AppStrings.sectionCompletedTimeUpMessage : AppStrings.sectionCompletedNaturalMessage;
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
              PrimaryButton(label: AppStrings.sectionCompletedContinueButton, onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}
