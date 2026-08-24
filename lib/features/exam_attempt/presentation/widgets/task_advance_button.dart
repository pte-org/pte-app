import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/timer_phase.dart';
import '../bloc/exam_attempt_bloc.dart';
import '../bloc/exam_attempt_event.dart';
import '../bloc/exam_attempt_state.dart';
import '../cubit/task_answer_cubit.dart';

/// The one explicit trigger allowed to submit the active task's answer
/// over the network (phase-05 Design Constraints): flushes whichever
/// [FlushableAnswerCubit] is currently on screen, then calls
/// `SyncEngine.flushOne` for [pinnedItemPublicId], then requests the next
/// task — in that order, so the very latest edit is never lost to an
/// in-flight debounce window and background flush never races this call.
/// Shared across every task-type screen (Phase 5/6) rather than
/// reimplemented per type.
///
/// Also self-triggers the identical sequence when the current task's
/// countdown reaches zero — the same "server is timing authority, client
/// timer is UX only" deadline this button already flushes against, so no
/// separate expiry check is needed. `_isAdvancing` guards both the tap
/// handler and the auto-trigger from firing twice for the same task.
class TaskAdvanceButton extends StatefulWidget {
  const TaskAdvanceButton({super.key, required this.cubit, required this.pinnedItemPublicId, required this.syncEngine});

  final FlushableAnswerCubit cubit;
  final String pinnedItemPublicId;
  final SyncEngine syncEngine;

  @override
  State<TaskAdvanceButton> createState() => _TaskAdvanceButtonState();
}

class _TaskAdvanceButtonState extends State<TaskAdvanceButton> {
  bool _isAdvancing = false;

  Future<void> _advance({AdvanceReason reason = AdvanceReason.manual}) async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);
    await widget.cubit.flushPendingEdit();
    await widget.syncEngine.flushOne(widget.pinnedItemPublicId);
    if (!mounted) return;
    context.read<ExamAttemptBloc>().add(NextTaskRequested(reason: reason));
  }

  bool _isExpired(ExamAttemptState state) {
    return state is AttemptInProgress &&
        state.timerSnapshot.phase == TimerPhase.response &&
        state.timerSnapshot.remaining == Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExamAttemptBloc, ExamAttemptState>(
      listenWhen: (previous, current) => !_isExpired(previous) && _isExpired(current),
      listener: (context, state) => _advance(reason: AdvanceReason.timeExpired),
      child: PrimaryButton(label: AppStrings.taskAdvanceButtonLabel, onPressed: _advance, isLoading: _isAdvancing),
    );
  }
}
