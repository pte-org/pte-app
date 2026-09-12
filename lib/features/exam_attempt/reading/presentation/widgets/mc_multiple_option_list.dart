import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/widgets/components/choice_list.dart';
import 'package:pte_app/core/widgets/components/choice_row.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_multiple_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_multiple_state.dart';

/// Multi-select list rendered from `TaskView.options`. Checking/unchecking
/// an option writes the full sorted selection immediately via
/// [McReadingMultipleCubit.toggleOption] — no debounce for a discrete
/// checkbox toggle.
class McMultipleOptionList extends StatelessWidget {
  const McMultipleOptionList({super.key, required this.options});

  final List<TaskOption> options;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<McReadingMultipleCubit, McReadingMultipleState>(
      builder: (context, state) {
        return ChoiceList(
          labels: [for (final option in options) option.text],
          selectedIndices: {
            for (var index = 0; index < options.length; index++)
              if (state.selectedOrderIndexes.contains(
                options[index].orderIndex,
              ))
                index,
          },
          mode: ChoiceSelectionMode.multiple,
          onTap: (index) => context.read<McReadingMultipleCubit>().toggleOption(
            options[index].orderIndex,
          ),
        );
      },
    );
  }
}
