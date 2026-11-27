import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/widgets/exam/exam_navigation_actions.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_navigation_constants.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';

/// The single forward-only Next button of the exam attempt (no Previous).
///
/// A tap submits whatever the student has (nothing becomes a blank answer),
/// moves the server pointer and asks the bloc for the next task. It is hidden
/// on the last task, where the app bar's Submit ends the exam, and disabled
/// while a submit is in flight and for a short cooldown after the task
/// appears so a double tap cannot skip the following task. The per-task timer
/// expiring takes the same path without the cooldown.
class TaskAdvanceButton extends StatefulWidget {
  const TaskAdvanceButton({
    super.key,
    this.cubit,
    this.pinnedItemPublicId,
    required this.syncEngine,
    this.autoAdvanceOnExpiration = true,
    this.beforeLeaving,
  });

  final FlushableAnswerCubit? cubit;
  final String? pinnedItemPublicId;
  final SyncEngine syncEngine;
  final bool autoAdvanceOnExpiration;

  /// Work the screen must finish before its answer is submitted, such as
  /// stopping a running recording so the partial file is kept. Bounded by
  /// [ExamAttemptNavigationConstants.leaveHookTimeout]; a failure or timeout
  /// never blocks Next.
  final Future<void> Function()? beforeLeaving;

  @override
  State<TaskAdvanceButton> createState() => _TaskAdvanceButtonState();
}

class _TaskAdvanceButtonState extends State<TaskAdvanceButton> {
  bool _isNavigating = false;
  bool _inCooldown = false;
  Timer? _cooldownTimer;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    // A task that appeared through an advance starts in cooldown; one shown
    // by a fresh start or resume has no activation time and is tappable.
    final activatedAt = context.read<ExamAttemptBloc>().taskActivatedAt;
    if (activatedAt == null) return;
    final remaining =
        ExamAttemptNavigationConstants.nextCooldown -
        DateTime.now().difference(activatedAt);
    if (remaining > Duration.zero) _startCooldown(remaining);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _settleTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(Duration duration) {
    _cooldownTimer?.cancel();
    _inCooldown = true;
    _cooldownTimer = Timer(duration, () {
      if (mounted) setState(() => _inCooldown = false);
    });
  }

  bool _isExpired(ExamAttemptState state) {
    return state is AttemptInProgress &&
        state.timerSnapshot.phase == TimerPhase.response &&
        state.timerSnapshot.remaining == Duration.zero;
  }

  /// Returns true only when the per-task timer expiring should auto-submit
  /// and advance. Rules:
  /// - READING/WRITING: never auto-advance (section timer is informational;
  ///   only force-submit or manual next commits answers).
  /// - LISTENING/SPEAKING: respect the caller's [widget.autoAdvanceOnExpiration].
  bool _shouldAutoAdvanceOnExpiration(AttemptInProgress state) {
    if (!widget.autoAdvanceOnExpiration) return false;
    final section = state.task.section.toUpperCase();
    if (section == 'READING' || section == 'WRITING') return false;
    return true;
  }

  /// Last only when the prefetched list and the server agree. The list alone
  /// is not enough: after a failed prefetch it holds just the current task.
  bool _isLastTask(AttemptInProgress state) =>
      state.currentIndex >= state.allTasks.length - 1 &&
      state.task.orderIndex + 1 >= state.task.totalTasks;

  Future<void> _runBeforeLeaving() async {
    final hook = widget.beforeLeaving;
    if (hook == null) return;
    try {
      await hook().timeout(ExamAttemptNavigationConstants.leaveHookTimeout);
    } catch (_) {
      // Leaving must not depend on the hook (the screen's close retries it).
    }
  }

  Future<void> _submitAndAdvance(AdvanceReason reason) async {
    if (_isNavigating) return;
    final bloc = context.read<ExamAttemptBloc>();
    final state = bloc.state;
    if (state is! AttemptInProgress) return;
    // The id of the task this screen shows, not whatever the bloc holds when
    // the tap is handled: a tap that outlived its task must not submit the
    // next one.
    final taskId = widget.pinnedItemPublicId ?? state.task.pinnedItemPublicId;
    if (taskId != state.task.pinnedItemPublicId) return;
    setState(() => _isNavigating = true);
    try {
      await widget.cubit?.flushPendingEdit();
      await _runBeforeLeaving();
      await widget.syncEngine.submitForAdvance(taskId);
    } catch (_) {
      // Leave the task in place so the student can tap Next again.
      if (mounted) setState(() => _isNavigating = false);
      return;
    }
    if (!mounted) return;
    // Naming the source task makes a second request for it harmless: once the
    // bloc has moved on, the event is stale and ignored.
    bloc.add(
      NextTaskRequested(
        reason: reason,
        fromPinnedItemPublicId: taskId,
        userInitiated: reason == AdvanceReason.manual,
      ),
    );
    // Stay locked: the next task replaces this screen, and a second tap before
    // that would re-submit a task the server has already moved past. The
    // timeout only frees the button when the bloc ignored the event.
    _settleTimer?.cancel();
    _settleTimer = Timer(
      ExamAttemptNavigationConstants.advanceSettleTimeout,
      () {
        if (mounted) setState(() => _isNavigating = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExamAttemptBloc, ExamAttemptState>(
      listenWhen: (previous, current) =>
          (!_isExpired(previous) &&
              _isExpired(current) &&
              current is AttemptInProgress &&
              _shouldAutoAdvanceOnExpiration(current)) ||
          (previous is AttemptInProgress &&
              current is AttemptInProgress &&
              previous.task.pinnedItemPublicId !=
                  current.task.pinnedItemPublicId),
      listener: (context, state) {
        if (state is! AttemptInProgress) return;
        if (_isExpired(state) && _shouldAutoAdvanceOnExpiration(state)) {
          unawaited(_submitAndAdvance(AdvanceReason.timeExpired));
          return;
        }
        _settleTimer?.cancel();
        // A new task is on screen: protect it from the previous task's tap.
        _startCooldown(ExamAttemptNavigationConstants.nextCooldown);
        setState(() => _isNavigating = false);
      },
      child: BlocBuilder<ExamAttemptBloc, ExamAttemptState>(
        builder: (context, state) {
          if (state is! AttemptInProgress || _isLastTask(state)) {
            return const SizedBox.shrink();
          }
          final ready = state.submissionStatus == AttemptSubmissionStatus.ready;
          return ExamNavigationActions(
            onPrevious: null,
            onNext: ready && !_isNavigating && !_inCooldown
                ? () => _submitAndAdvance(AdvanceReason.manual)
                : null,
            nextLabel:
                state.submissionStatus == AttemptSubmissionStatus.submitting
                ? ExamAttemptStrings.forceSubmitSubmittingLabel
                : ExamAttemptStrings.taskAdvanceButtonLabel,
            nextLoading:
                _isNavigating ||
                state.submissionStatus == AttemptSubmissionStatus.submitting,
          );
        },
      ),
    );
  }
}
