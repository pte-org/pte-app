import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/features/exam_attempt/domain/task_navigation_direction.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/task_answer_cubit.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Shared candidate navigation. Manual movement first saves the local draft
/// without advancing the server pointer, then asks the backend to move in the
/// requested direction. Timer expiry retains the existing submit-and-advance
/// behavior.
class TaskAdvanceButton extends StatefulWidget {
  const TaskAdvanceButton({
    super.key,
    this.cubit,
    this.pinnedItemPublicId,
    required this.syncEngine,
    this.autoAdvanceOnExpiration = true,
  });

  final FlushableAnswerCubit? cubit;
  final String? pinnedItemPublicId;
  final SyncEngine syncEngine;
  final bool autoAdvanceOnExpiration;

  @override
  State<TaskAdvanceButton> createState() => _TaskAdvanceButtonState();
}

class _TaskAdvanceButtonState extends State<TaskAdvanceButton> {
  bool _isNavigating = false;
  String? _pendingTaskId;

  bool _isExpired(ExamAttemptState state) {
    return state is AttemptInProgress &&
        state.timerSnapshot.phase == TimerPhase.response &&
        state.timerSnapshot.remaining == Duration.zero;
  }

  /// Returns true only when the per-task timer expiring should auto-submit
  /// and advance. Rules:
  /// - Practice mode: never auto-advance (student controls their own pace).
  /// - Official READING/WRITING: never auto-advance (section timer is
  ///   informational; only force-submit or manual next chốt answers).
  /// - Official LISTENING/SPEAKING: respect the caller's [widget.autoAdvanceOnExpiration].
  bool _shouldAutoAdvanceOnExpiration(AttemptInProgress state) {
    if (!widget.autoAdvanceOnExpiration) return false;
    if (state.isPractice) return false;
    final section = state.task.section.toUpperCase();
    if (section == 'READING' || section == 'WRITING') return false;
    return true;
  }

  Future<void> _advanceOnExpiration() async {
    if (_isNavigating) return;
    final state = context.read<ExamAttemptBloc>().state;
    if (state is! AttemptInProgress) return;
    setState(() {
      _isNavigating = true;
      _pendingTaskId = state.task.pinnedItemPublicId;
    });
    await widget.cubit?.flushPendingEdit();
    await widget.syncEngine.flushOne(state.task.pinnedItemPublicId);
    if (!mounted) return;
    context.read<ExamAttemptBloc>().add(
      const NextTaskRequested(reason: AdvanceReason.timeExpired),
    );
  }

  Future<void> _navigate(
    TaskView task,
    TaskNavigationDirection direction,
  ) async {
    if (_isNavigating) return;
    final canNavigate = direction == TaskNavigationDirection.previous
        ? task.canNavigatePrevious
        : task.canNavigateNext;
    if (!canNavigate) return;

    setState(() {
      _isNavigating = true;
      _pendingTaskId = task.pinnedItemPublicId;
    });
    try {
      // Cubits start from an empty default when a task screen is recreated.
      // Do not flush that default when the student revisits an existing task
      // and leaves it untouched, or it would overwrite the previous answer.
      if (widget.cubit?.hasPendingEdits ?? false) {
        await widget.cubit!.flushPendingEdit();
      }
      await widget.syncEngine.flushOne(task.pinnedItemPublicId, advance: false);
      if (!mounted) return;
      context.read<ExamAttemptBloc>().add(
        NavigateTaskRequested(
          fromPinnedItemPublicId: task.pinnedItemPublicId,
          direction: direction,
        ),
      );
      // Navigation is synchronous in the BLoC; reset immediately so the
      // button never gets permanently stuck if the state did not change
      // (e.g. allTasks fallback with a single entry).
      if (mounted) {
        setState(() {
          _isNavigating = false;
          _pendingTaskId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
          _pendingTaskId = null;
        });
      }
      rethrow;
    }
  }

  void _handleStateChange(ExamAttemptState state) {
    if (_isExpired(state) && state is AttemptInProgress && _shouldAutoAdvanceOnExpiration(state)) {
      _advanceOnExpiration();
      return;
    }
    if (state is AttemptError ||
        state is AttemptCompleted ||
        (state is AttemptInProgress &&
            _pendingTaskId != null &&
            state.task.pinnedItemPublicId != _pendingTaskId)) {
      setState(() {
        _isNavigating = false;
        _pendingTaskId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExamAttemptBloc, ExamAttemptState>(
      listenWhen: (previous, current) =>
          (!_isExpired(previous) &&
              _isExpired(current) &&
              current is AttemptInProgress &&
              _shouldAutoAdvanceOnExpiration(current)) ||
          current is AttemptError ||
          current is AttemptCompleted ||
          (current is AttemptInProgress &&
              _pendingTaskId != null &&
              current.task.pinnedItemPublicId != _pendingTaskId),
      listener: (context, state) => _handleStateChange(state),
      child: BlocBuilder<ExamAttemptBloc, ExamAttemptState>(
        builder: (context, state) {
          if (state is! AttemptInProgress) return const SizedBox.shrink();
          final task = state.task;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: !_isNavigating && task.canNavigatePrevious
                    ? () => _navigate(task, TaskNavigationDirection.previous)
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppDimensions.buttonHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd,
                  ),
                ),
                child: const Text(ExamChromeConfig.previousLabel),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              PrimaryButton(
                label: ExamAttemptStrings.taskAdvanceButtonLabel,
                onPressed: task.canNavigateNext
                    ? () => _navigate(task, TaskNavigationDirection.next)
                    : null,
                isLoading: _isNavigating,
              ),
            ],
          );
        },
      ),
    );
  }
}
