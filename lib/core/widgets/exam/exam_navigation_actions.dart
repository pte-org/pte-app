import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/widgets/primary_button.dart';

/// Shared Previous/Next action group used by both the exam footer and live
/// task screens. Keeping the buttons here prevents a task family from
/// drifting away from the shell's interaction and spacing rules.
class ExamNavigationActions extends StatelessWidget {
  const ExamNavigationActions({
    super.key,
    required this.onPrevious,
    required this.onNext,
    this.nextLabel = ExamChromeConfig.nextLabel,
    this.nextLoading = false,
    this.nextAction,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool nextLoading;
  final Widget? nextAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: onPrevious,
          style: _previousStyle(),
          child: const Text(ExamChromeConfig.previousLabel),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        nextAction ??
            PrimaryButton(
              label: nextLabel,
              onPressed: onNext,
              isLoading: nextLoading,
            ),
      ],
    );
  }

  ButtonStyle _previousStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, AppDimensions.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      foregroundColor: AppColors.brandPrimary,
      disabledForegroundColor: AppColors.textMuted,
      side: const BorderSide(color: AppColors.brandPrimary),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.radiusDefault),
        ),
      ),
      textStyle: AppTypography.bodyBold,
    );
  }
}
