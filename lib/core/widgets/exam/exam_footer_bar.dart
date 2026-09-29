import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/widgets/exam/exam_navigation_actions.dart';

/// Pure footer shell. Task navigation is injected by the exam feature.
class ExamFooterBar extends StatelessWidget {
  const ExamFooterBar({
    super.key,
    this.onNext,
    this.navigationActions,
    this.nextAction,
    this.nextLabel = ExamChromeConfig.nextLabel,
    this.nextLoading = false,
  });

  final VoidCallback? onNext;
  final Widget? navigationActions;
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
          const Spacer(),
          if (navigationActions != null)
            navigationActions!
          else
            ExamNavigationActions(
              onPrevious: null,
              onNext: onNext,
              nextLabel: nextLabel,
              nextLoading: nextLoading,
              nextAction: nextAction,
            ),
        ],
      ),
    );
  }
}
