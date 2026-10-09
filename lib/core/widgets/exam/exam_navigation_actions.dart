import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/core/widgets/secondary_button.dart';

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
        SecondaryButton(
          label: ExamChromeConfig.previousLabel,
          onPressed: onPrevious,
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
}
