import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        return ListView(
          children: [
            for (final option in options)
              CheckboxListTile(
                title: Text(option.text),
                value: state.selectedOrderIndexes.contains(option.orderIndex),
                onChanged: (_) => context.read<McReadingMultipleCubit>().toggleOption(option.orderIndex),
              ),
          ],
        );
      },
    );
  }
}
