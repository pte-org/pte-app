import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/widgets/confirm_dialog.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Phase label + countdown + `orderIndex`/`totalTasks` + a force-submit
/// affordance. Reads only the [TimerSnapshot] slice of [ExamAttemptState]
/// via [BlocSelector] so unrelated attempt-state changes elsewhere never
/// force a rebuild here (phase-04 Design Constraints) — `totalTasks` is
/// passed in by the caller since it doesn't change while a single task is
/// displayed.
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
              Text(
                // currentOrderIndex is 0-based (server/domain convention);
                // display is 1-based ("Question 1 of N"), matching the real
                // exam's counter, not the internal index.
                '${snapshot.currentOrderIndex + 1}${ExamAttemptStrings.examTaskCounterOf}$totalTasks',
                style: const TextStyle(color: AppColors.onPrimary),
              ),
              const Spacer(),
              Text(_phaseLabel(snapshot.phase), style: const TextStyle(color: AppColors.onPrimary)),
              const SizedBox(width: AppDimensions.spacingMedium),
              Text(
                _formatRemaining(snapshot.remaining),
                key: const ValueKey('examAppBarCountdown'),
                style: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.onPrimary),
                tooltip: ExamAttemptStrings.forceSubmitButtonLabel,
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
      title: ExamAttemptStrings.forceSubmitDialogTitle,
      message: ExamAttemptStrings.forceSubmitDialogMessage,
      confirmLabel: ExamAttemptStrings.forceSubmitDialogConfirm,
      cancelLabel: ExamAttemptStrings.forceSubmitDialogCancel,
    );
    if (confirmed) {
      bloc.add(const ForceSubmitRequested());
    }
  }

  String _phaseLabel(TimerPhase phase) {
    return switch (phase) {
      TimerPhase.prep => ExamAttemptStrings.examPhasePrepLabel,
      TimerPhase.response => ExamAttemptStrings.examPhaseResponseLabel,
    };
  }

  String _formatRemaining(Duration remaining) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(remaining.inMinutes)}:${twoDigits(remaining.inSeconds % 60)}';
  }
}
