import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/widgets/exam/exam_header_bar.dart';
import 'package:pte_app/core/widgets/confirm_dialog.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Feature-bound adapter from [ExamAttemptState] to the pure design header.
class ExamAppBar extends StatelessWidget {
  const ExamAppBar({super.key, required this.totalTasks});

  final int totalTasks;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamAttemptBloc, ExamAttemptState>(
      builder: (context, state) {
        final inProgress = state is AttemptInProgress ? state : null;
        final snapshot = inProgress?.timerSnapshot;
        final item = ExamChromeConfig.itemLabel(
          orderIndex: snapshot?.currentOrderIndex,
          totalTasks: totalTasks,
        );
        return ExamHeaderBar(
          examTitle: ExamChromeConfig.defaultExamTitle,
          candidateName: 'Candidate',
          candidateId: ExamChromeConfig.unavailableCandidateId,
          itemLabel: item,
          timeLabel: ExamChromeConfig.formatDuration(snapshot?.remaining),
          timeContent: const _ExamTimerLabel(),
          onForceSubmit: () => _confirmAndForceSubmit(context),
        );
      },
    );
  }

  Future<void> _confirmAndForceSubmit(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: ExamAttemptStrings.forceSubmitDialogTitle,
      message: ExamAttemptStrings.forceSubmitDialogMessage,
      confirmLabel: ExamAttemptStrings.forceSubmitDialogConfirm,
      cancelLabel: ExamAttemptStrings.forceSubmitDialogCancel,
    );
    if (confirmed && context.mounted) {
      context.read<ExamAttemptBloc>().add(const ForceSubmitRequested());
    }
  }
}

class _ExamTimerLabel extends StatelessWidget {
  const _ExamTimerLabel();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExamAttemptBloc, ExamAttemptState, Duration?>(
      selector: (state) =>
          state is AttemptInProgress ? state.timerSnapshot.remaining : null,
      builder: (context, remaining) => Text(
        ExamChromeConfig.formatDuration(remaining),
        key: const ValueKey('examAppBarCountdown'),
        style: AppTypography.timerTabular.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
