import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';

/// Pure navigation footer. Previous is intentionally always disabled for the
/// forward-only exam flow; task-specific advance behavior is injected.
class ExamFooterBar extends StatelessWidget {
  const ExamFooterBar({
    super.key,
    this.onSaveAndExit,
    this.onNext,
    this.nextAction,
    this.nextLabel = ExamChromeConfig.nextLabel,
    this.nextLoading = false,
  });

  final VoidCallback? onSaveAndExit;
  final VoidCallback? onNext;
  final Widget? nextAction;
  final String nextLabel;
  final bool nextLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.examFooterHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: onSaveAndExit,
            style: _outlineStyle(),
            child: const Text(ExamChromeConfig.saveAndExitLabel),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: null,
            style: _outlineStyle(),
            child: const Text(ExamChromeConfig.previousLabel),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          if (nextAction != null)
            nextAction!
          else
            FilledButton(
              onPressed: nextLoading ? null : onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppDimensions.buttonHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                ),
                backgroundColor: AppColors.brandPrimary,
                disabledBackgroundColor: AppColors.inactive,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
                textStyle: AppTypography.bodyBold,
              ),
              child: nextLoading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(nextLabel),
            ),
        ],
      ),
    );
  }

  ButtonStyle _outlineStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, AppDimensions.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      foregroundColor: AppColors.brandPrimary,
      side: const BorderSide(color: AppColors.brandPrimary),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      textStyle: AppTypography.bodyBold,
    );
  }
}
