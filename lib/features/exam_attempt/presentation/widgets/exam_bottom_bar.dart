import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';

/// Container + a single [action] slot — the actual submit/advance affordance
/// is wired by the task-type screen that embeds this bar (Phase 5/6/7), not
/// built here (phase-04 Design Constraints). Always a neutral light-gray
/// background, not phase-driven — the countdown/phase itself is conveyed by
/// `ExamAppBar` and each task screen's own body.
class ExamBottomBar extends StatelessWidget {
  const ExamBottomBar({super.key, this.action});

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.examBottomBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMedium),
      color: AppColors.examBottomBarNeutral,
      alignment: Alignment.centerRight,
      child: action ?? const SizedBox.shrink(),
    );
  }
}
