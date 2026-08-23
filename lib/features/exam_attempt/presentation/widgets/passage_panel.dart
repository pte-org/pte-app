import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

/// Scrollable bordered panel that hosts the reading passage or essay prompt.
/// Capped at [maxHeight] so the panel never crowds out the editor on small
/// screens; long passages scroll inside the panel.
class PassagePanel extends StatelessWidget {
  const PassagePanel({super.key, required this.body, this.maxHeight = AppDimensions.passagePanelMaxHeight});

  final String body;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.passagePanelBackground,
        border: Border.all(color: AppColors.passagePanelBorder, width: AppDimensions.passagePanelBorderWidth),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.passagePanelLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            SelectableText(body, style: const TextStyle(color: AppColors.textPrimary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
