import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

/// Bordered card showing the read-aloud instructions above the scrollable
/// passage text — rendered during both the prep and response phases
/// (the passage never disappears once shown). The instruction text is
/// templated from [responseSeconds], never a hardcoded "40 seconds", since
/// every task's response window differs.
class ReadAloudPassagePanel extends StatelessWidget {
  const ReadAloudPassagePanel({super.key, required this.promptText, required this.responseSeconds});

  final String promptText;
  final int responseSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.fillBlanksGapEmptyBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_instructionText(), style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.spacingMedium),
          Expanded(
            child: SingleChildScrollView(
              child: Text(promptText, style: const TextStyle(color: AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  String _instructionText() {
    return '${AppStrings.readAloudInstructionPrefix}$responseSeconds'
        '${AppStrings.readAloudInstructionMiddle}$responseSeconds'
        '${AppStrings.readAloudInstructionSuffix}';
  }
}
