import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/task_view.dart';
import '../cubit/mc_reading_single_cubit.dart';
import '../cubit/mc_reading_single_state.dart';

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
        return RadioGroup<String>(
          groupValue: state.selectedOrderIndex,
          onChanged: (value) {
            if (value != null) context.read<McReadingSingleCubit>().selectOption(value);
          },
          child: ListView(
            children: [
              for (final option in options) RadioListTile<String>(title: Text(option.text), value: option.orderIndex),
            ],
          ),
        );
      },
    );
  }
}
