import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/widgets/components/choice_list.dart';
import 'package:pte_app/core/widgets/components/choice_row.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_single_cubit.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_single_state.dart';

/// Single-select list rendered from `TaskView.options`. Selecting an
/// option writes its `orderIndex` immediately via
/// [McReadingSingleCubit.selectOption] — no debounce for a single tap
/// (phase-05 Design Constraints).
class McOptionList extends StatelessWidget {
  const McOptionList({super.key, required this.options});

  final List<TaskOption> options;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<McReadingSingleCubit, McReadingSingleState>(
      builder: (context, state) {
        final selectedIndices = {
          for (var index = 0; index < options.length; index++)
            if (options[index].orderIndex == state.selectedOrderIndex) index,
        };
        return ChoiceList(
          labels: [for (final option in options) option.text],
          selectedIndices: selectedIndices,
          mode: ChoiceSelectionMode.single,
          onTap: (index) => context.read<McReadingSingleCubit>().selectOption(
            options[index].orderIndex,
          ),
        );
      },
    );
  }
}
