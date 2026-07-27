import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/sync/sync_engine.dart';
import '../bloc/exam_attempt_bloc.dart';
import '../bloc/exam_attempt_event.dart';
import '../cubit/task_answer_cubit.dart';

/// The one explicit trigger allowed to submit the active task's answer
/// over the network (phase-05 Design Constraints): flushes whichever
/// [FlushableAnswerCubit] is currently on screen, then calls
/// `SyncEngine.flushOne` for [pinnedItemPublicId], then requests the next
/// task — in that order, so the very latest edit is never lost to an
/// in-flight debounce window and background flush never races this call.
/// Shared across every task-type screen (Phase 5/6) rather than
/// reimplemented per type.
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

  Future<void> _advance() async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);
    await widget.cubit.flushPendingEdit();
    await widget.syncEngine.flushOne(widget.pinnedItemPublicId);
    if (!mounted) return;
    context.read<ExamAttemptBloc>().add(const NextTaskRequested());
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isAdvancing ? null : _advance,
      child: _isAdvancing
          ? const SizedBox(
              width: AppDimensions.advanceButtonSpinnerSize,
              height: AppDimensions.advanceButtonSpinnerSize,
              child: CircularProgressIndicator(strokeWidth: AppDimensions.advanceButtonSpinnerStrokeWidth),
            )
          : const Text(AppStrings.taskAdvanceButtonLabel),
    );
  }
}
