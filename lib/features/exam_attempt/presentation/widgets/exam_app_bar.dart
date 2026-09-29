import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/widgets/exam/exam_header_bar.dart';
import 'package:pte_app/core/widgets/confirm_dialog.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Feature-bound adapter from [ExamAttemptState] to the pure design header.
class ExamAppBar extends StatelessWidget {
  const ExamAppBar({
    super.key,
    required this.totalTasks,
    this.outboxDao,
  });

  final int totalTasks;
  final AnswerOutboxDao? outboxDao;

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
        final submissionStatus =
            inProgress?.submissionStatus ?? AttemptSubmissionStatus.ready;
        final finishLabel = switch (submissionStatus) {
          AttemptSubmissionStatus.ready => ExamChromeConfig.finishExamLabel,
          AttemptSubmissionStatus.submitting =>
            ExamChromeConfig.submittingExamLabel,
          AttemptSubmissionStatus.retryableFailure =>
            ExamAttemptStrings.forceSubmitRetryLabel,
        };
        return ExamHeaderBar(
          examTitle: ExamChromeConfig.defaultExamTitle,
          candidateName: 'Candidate',
          candidateId: ExamChromeConfig.unavailableCandidateId,
          itemLabel: item,
          timeLabel: ExamChromeConfig.formatDuration(snapshot?.remaining),
          timeContent: const _ExamGlobalTimerLabel(),
          onForceSubmit: submissionStatus == AttemptSubmissionStatus.submitting
              ? null
              : () => _confirmAndForceSubmit(context),
          finishLabel: finishLabel,
          finishLoading: submissionStatus == AttemptSubmissionStatus.submitting,
        );
      },
    );
  }

  Future<void> _confirmAndForceSubmit(BuildContext context) async {
    final state = context.read<ExamAttemptBloc>().state;
    if (state is! AttemptInProgress ||
        state.submissionStatus == AttemptSubmissionStatus.submitting) {
      return;
    }
    final answeredTasks = await (outboxDao?.countAnsweredByAttempt(
          state.attemptPublicId,
        ) ??
        Future<int>.value(0));
    if (!context.mounted) return;
    final total = state.task.totalTasks > 0 ? state.task.totalTasks : totalTasks;
    final unanswered = total - answeredTasks;
    final unansweredTasks = unanswered < 0 ? 0 : unanswered;
    final confirmed = await showConfirmDialog(
      context,
      title: ExamAttemptStrings.forceSubmitDialogTitle,
      message: ExamAttemptStrings.forceSubmitDialogMessage(
        answeredTasks: answeredTasks,
        unansweredTasks: unansweredTasks,
      ),
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
class _ExamGlobalTimerLabel extends StatelessWidget {
  const _ExamGlobalTimerLabel();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExamAttemptBloc, ExamAttemptState,
        _ExamGlobalTimerSelection?>(
      selector: (state) {
        if (state is! AttemptInProgress) return null;
        return _ExamGlobalTimerSelection(
          examEndTime: state.task.examEndTime,
          fallbackRemaining: state.timerSnapshot.remaining,
        );
      },
      builder: (context, selection) => _ExamGlobalTimerText(
        selection: selection,
      ),
    );
  }
}

class _ExamGlobalTimerSelection extends Equatable {
  const _ExamGlobalTimerSelection({
    required this.examEndTime,
    required this.fallbackRemaining,
  });

  final DateTime? examEndTime;
  final Duration fallbackRemaining;

  @override
  List<Object?> get props => [examEndTime, fallbackRemaining];
}

class _ExamGlobalTimerText extends StatefulWidget {
  const _ExamGlobalTimerText({required this.selection});

  final _ExamGlobalTimerSelection? selection;

  @override
  State<_ExamGlobalTimerText> createState() => _ExamGlobalTimerTextState();
}

class _ExamGlobalTimerTextState extends State<_ExamGlobalTimerText> {
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

  @override
  void didUpdateWidget(covariant _ExamGlobalTimerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      _update();
    }
  }

  Duration? _compute() {
    final selection = widget.selection;
    if (selection == null) return null;
    final examEndTime = selection.examEndTime;
    if (examEndTime == null) return selection.fallbackRemaining;
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
