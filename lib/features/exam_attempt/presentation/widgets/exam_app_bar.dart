import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/duration_format.dart';
import '../../domain/timer_snapshot.dart';
import '../bloc/exam_attempt_bloc.dart';
import '../bloc/exam_attempt_state.dart';

/// Static brand block + phase/countdown + `orderIndex`/`totalTasks`. Reads
/// only the [TimerSnapshot] slice of [ExamAttemptState] via [BlocSelector]
/// so unrelated attempt-state changes elsewhere never force a rebuild here
/// (phase-04 Design Constraints) — `totalTasks` is passed in by the caller
/// since it doesn't change while a single task is displayed.
///
/// No force-submit affordance here anymore — removed per product decision;
/// `ForceSubmitRequested`/`ExamAttemptRepository.forceSubmit` still exist
/// and are still tested (phase-07), just currently unreachable from any UI.
class ExamAppBar extends StatelessWidget {
  const ExamAppBar({super.key, required this.totalTasks});

  final int totalTasks;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerSnapshot?>(
      selector: (state) => state is AttemptInProgress ? state.timerSnapshot : null,
      builder: (context, snapshot) {
        if (snapshot == null) return const SizedBox.shrink();
        return Container(
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMedium,
            vertical: AppDimensions.spacingMedium,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _BrandBlock()),
              _CountdownBlock(snapshot: snapshot, totalTasks: totalTasks),
            ],
          ),
        );
      },
    );
  }
}

/// Static branding — same 3 lines on every task-type screen, not sourced
/// from any tenant/account data (none is plumbed into this app yet).
class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.examBrandLine1,
          style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: AppDimensions.examBrandFontSize),
        ),
        Text(AppStrings.examBrandLine2, style: TextStyle(color: AppColors.onPrimary, fontSize: AppDimensions.examBrandFontSize)),
        Text(AppStrings.examBrandLine3, style: TextStyle(color: AppColors.onPrimary, fontSize: AppDimensions.examBrandFontSize)),
      ],
    );
  }
}

/// "Time Remaining {examRemaining}" on one line, `orderIndex`/`totalTasks`
/// on the next — mirrors the reference layout's "Time Remaining 00:39:16" /
/// "5 of 32" block exactly. Shows the whole-exam countdown, not the
/// per-task prep/response one (that distinction is conveyed by each task
/// screen's own body instead, e.g. the read-aloud "Recorded Answer" card).
class _CountdownBlock extends StatelessWidget {
  const _CountdownBlock({required this.snapshot, required this.totalTasks});

  final TimerSnapshot snapshot;
  final int totalTasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${AppStrings.examTimeRemainingLabel}${formatHhMmSs(snapshot.examRemaining)}',
          key: const ValueKey('examAppBarCountdown'),
          style: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
        ),
        Text(
          '${snapshot.currentOrderIndex}${AppStrings.examTaskCounterOf}$totalTasks',
          style: const TextStyle(color: AppColors.onPrimary),
        ),
      ],
    );
  }
}
