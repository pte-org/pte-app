import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/timer_phase.dart';
import '../../domain/timer_snapshot.dart';
import '../bloc/exam_attempt_bloc.dart';
import '../bloc/exam_attempt_event.dart';
import '../bloc/exam_attempt_state.dart';

/// Phase indicator + `orderIndex`/`totalTasks` + countdown display. Reads
/// only the [TimerSnapshot] slice of [ExamAttemptState] via [BlocSelector]
/// so unrelated attempt-state changes elsewhere never force a rebuild here
/// (phase-04 Design Constraints) — `totalTasks` is passed in by the caller
/// since it doesn't change while a single task is displayed.
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
            children: [
              Text(_phaseLabel(snapshot.phase), style: const TextStyle(color: AppColors.onPrimary)),
              const Spacer(),
              Text(
                _formatRemaining(snapshot.remaining),
                style: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              Text(
                '${snapshot.currentOrderIndex}${AppStrings.examTaskCounterOf}$totalTasks',
                style: const TextStyle(color: AppColors.onPrimary),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.onPrimary),
                tooltip: AppStrings.forceSubmitButtonLabel,
                onPressed: () => _confirmAndForceSubmit(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Force-submit is irreversible (phase-07 Design Constraints) — always
  /// gated behind an explicit confirm step, never dispatched directly from
  /// the tap.
  Future<void> _confirmAndForceSubmit(BuildContext context) async {
    final bloc = context.read<ExamAttemptBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.forceSubmitDialogTitle,
      message: AppStrings.forceSubmitDialogMessage,
      confirmLabel: AppStrings.forceSubmitDialogConfirm,
      cancelLabel: AppStrings.forceSubmitDialogCancel,
    );
    if (confirmed) {
      bloc.add(const ForceSubmitRequested());
    }
  }

  String _phaseLabel(TimerPhase phase) {
    return switch (phase) {
      TimerPhase.prep => AppStrings.examPhasePrepLabel,
      TimerPhase.response => AppStrings.examPhaseResponseLabel,
    };
  }

  String _formatRemaining(Duration remaining) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(remaining.inMinutes)}:${twoDigits(remaining.inSeconds % 60)}';
  }
}
