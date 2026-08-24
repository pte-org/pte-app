import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/primary_button.dart';

/// PTE-style Reading section instructions (Screen 1 of the Reading flow).
/// Purely informational — the countdown/attempt only actually starts once
/// [onContinue] leads to the real session-start call, never from this
/// screen itself.
class ReadingInstructionsScreen extends StatelessWidget {
  const ReadingInstructionsScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.readingInstructionsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(AppStrings.readingInstructionsBody),
            const SizedBox(height: AppDimensions.spacingMedium),
            Align(
              alignment: Alignment.centerRight,
              child: PrimaryButton(label: AppStrings.readingInstructionsButtonLabel, onPressed: onContinue),
            ),
          ],
        ),
      ),
    );
  }
}
