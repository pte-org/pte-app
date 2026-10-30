import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_dropdown_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_dropdown_state.dart';
import 'inline_blank_dropdown_passage.dart';

/// Binds the common inline passage to the student's persisted answer state.
class FillBlanksDropdownBody extends StatelessWidget {
  const FillBlanksDropdownBody({super.key, required this.task});
  final TaskView task;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FillBlanksDropdownCubit, FillBlanksDropdownState>(
    builder: (context, state) => InlineBlankDropdownPassage(
      promptText: task.promptText ?? '',
      optionsByGap: {
        for (final group in task.blankGroups ?? const <BlankGroup>[])
          group.blankIndex: [
            for (final option in group.options)
              InlineBlankChoice(value: option.orderIndex, text: option.text),
          ],
      },
      values: {
        for (var index = 0; index < state.selectedOrderIndexes.length; index++)
          if (state.selectedOrderIndexes[index] != null)
            index: state.selectedOrderIndexes[index]!,
      },
      onChanged: context.read<FillBlanksDropdownCubit>().selectOption,
    ),
  );
}
