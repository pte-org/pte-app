import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/widgets/primary_button.dart';

class HostPreviewNavigation extends StatelessWidget {
  const HostPreviewNavigation({
    super.key,
    required this.canGoBack,
    required this.isLast,
    required this.isBusy,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  final bool canGoBack;
  final bool isLast;
  final bool isBusy;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingMd,
          AppDimensions.spacingSm + AppDimensions.spacingXs,
          AppDimensions.spacingMd,
          AppDimensions.spacingMd,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: isBusy || !canGoBack ? null : onPrevious,
              child: const Text(ExamPreviewStrings.previous),
            ),
            const Spacer(),
            PrimaryButton(
              label: isLast
                  ? ExamPreviewStrings.finish
                  : ExamPreviewStrings.next,
              onPressed: isBusy ? null : (isLast ? onFinish : onNext),
              isLoading: isBusy,
            ),
          ],
        ),
      ),
    );
  }
}
