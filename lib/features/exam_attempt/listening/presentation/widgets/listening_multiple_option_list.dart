import 'package:flutter/material.dart';

import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

/// Pure presentational multi-select list — decoupled counterpart to
/// Reading's `McMultipleOptionList` (same coupling issue as
/// `ListeningOptionList`'s doc-comment explains). Takes
/// [selectedOrderIndexes] and [onToggle] as plain props.
class ListeningMultipleOptionList extends StatelessWidget {
  const ListeningMultipleOptionList({
    super.key,
    required this.options,
    required this.selectedOrderIndexes,
    required this.onToggle,
  });

  final List<TaskOption> options;
  final Set<String> selectedOrderIndexes;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final option in options)
          CheckboxListTile(
            title: Text(option.text),
            value: selectedOrderIndexes.contains(option.orderIndex),
            onChanged: (_) => onToggle(option.orderIndex),
          ),
      ],
    );
  }
}
