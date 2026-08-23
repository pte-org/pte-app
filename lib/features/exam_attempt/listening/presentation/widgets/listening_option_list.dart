import 'package:flutter/material.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

/// Pure presentational single-select list — decoupled counterpart to
/// Reading's `McOptionList`, which hardcodes
/// `BlocBuilder<McReadingSingleCubit, _>` internally and therefore cannot
/// render against any listening cubit (phase-03 red-team finding). Takes
/// [selectedOrderIndex] and [onChanged] as plain props; the caller's own
/// `BlocBuilder` supplies both. Shared by `MC_LISTENING_SINGLE`,
/// `SELECT_MISSING_WORD`, and `HIGHLIGHT_CORRECT_SUMMARY` (phase-04
/// reuses this as-is).
class ListeningOptionList extends StatelessWidget {
  const ListeningOptionList({super.key, required this.options, required this.selectedOrderIndex, required this.onChanged});

  final List<TaskOption> options;
  final String? selectedOrderIndex;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selectedOrderIndex,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: ListView(
        children: [for (final option in options) RadioListTile<String>(title: Text(option.text), value: option.orderIndex)],
      ),
    );
  }
}
