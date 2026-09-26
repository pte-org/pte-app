import 'dart:async';

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
          timeContent: const _ExamGlobalTimerLabel(),
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

/// Counts down the whole-attempt deadline (`TaskView.examEndTime`) rather than
/// the current task's remaining slice, so the displayed time reflects total
/// exam time left regardless of which task is active or which mode is used.
/// Falls back to the per-task `timerSnapshot.remaining` for attempts created
/// before the backend started populating `examEndTime`.
class _ExamGlobalTimerLabel extends StatefulWidget {
  const _ExamGlobalTimerLabel();

  @override
  State<_ExamGlobalTimerLabel> createState() => _ExamGlobalTimerLabelState();
}

class _ExamGlobalTimerLabelState extends State<_ExamGlobalTimerLabel> {
  Timer? _ticker;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    // Compute synchronously so the first build frame shows the real value,
    // not "--:--". context.read is safe here — BlocProvider is already above
    // in the tree when initState runs (same pattern as AutoRecordTimerBridgeMixin).
    _remaining = _compute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _update();
    });
  }

  Duration? _compute() {
    final state = context.read<ExamAttemptBloc>().state;
    if (state is! AttemptInProgress) return null;
    final examEndTime = state.task.examEndTime;
    if (examEndTime == null) return state.timerSnapshot.remaining;
    final diff = examEndTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  void _update() {
    final next = _compute();
    if (next != null) setState(() => _remaining = next);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      ExamChromeConfig.formatDuration(_remaining),
      key: const ValueKey('examAppBarCountdown'),
      style: AppTypography.timerTabular.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }
}
