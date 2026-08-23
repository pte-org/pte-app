import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';

/// Container + phase-driven visual switch only. The contract has no
/// "previous task" or flag concept, so unlike the old reference scaffold
/// this exposes a single [action] slot — the actual submit/advance
/// affordance is wired by the task-type screen that embeds this bar
/// (Phase 5/6/7), not built here (phase-04 Design Constraints).
class ExamBottomBar extends StatelessWidget {
  const ExamBottomBar({super.key, this.action});

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerPhase?>(
      selector: (state) => state is AttemptInProgress ? state.timerSnapshot.phase : null,
      builder: (context, phase) {
        return Container(
          height: AppDimensions.examBottomBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMedium),
          color: phase == TimerPhase.prep ? AppColors.examBottomBarPrep : AppColors.examBottomBarResponse,
          alignment: Alignment.centerRight,
          child: action ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
