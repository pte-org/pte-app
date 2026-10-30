import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import '../cubit/fill_blanks_drag_drop_cubit.dart';
import '../cubit/fill_blanks_drag_drop_state.dart';
import 'inline_drag_drop_passage.dart';

class FillBlanksDragDropBody extends StatelessWidget {
  const FillBlanksDragDropBody({super.key, required this.task});
  final TaskView task;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FillBlanksDragDropCubit, FillBlanksDragDropState>(
      builder: (context, state) {
        final cubit = context.read<FillBlanksDragDropCubit>();
        return InlineDragDropPassage(
          promptText: task.promptText ?? '',
          options: task.options ?? const [],
          assignments: state.gapAssignments,
          onAssign: cubit.assignToGap,
          onClear: cubit.clearGap,
        );
      },
    );
  }
}
