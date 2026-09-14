import 'package:flutter/material.dart';

import 'choice_row.dart';

class ChoiceList extends StatelessWidget {
  const ChoiceList({
    super.key,
    required this.labels,
    required this.selectedIndices,
    required this.mode,
    required this.onTap,
  });

  final List<String> labels;
  final Set<int> selectedIndices;
  final ChoiceSelectionMode mode;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          ChoiceRow(
            label: labels[index],
            selected: selectedIndices.contains(index),
            mode: mode,
            onTap: () => onTap(index),
          ),
          if (index < labels.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
