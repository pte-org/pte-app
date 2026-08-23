import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';

/// Pure presentational click-to-toggle word list for
/// `HIGHLIGHT_INCORRECT_WORDS` — the one genuinely new UI pattern in this
/// plan (phase-04 Design Constraints). Each word is its own tappable
/// widget in a `Wrap` so text wraps naturally across lines; [ValueKey] per
/// index keeps Flutter from reusing/reordering word Elements when
/// [selectedIndices] changes.
class WordSelectionList extends StatelessWidget {
  const WordSelectionList({super.key, required this.words, required this.selectedIndices, required this.onToggle});

  final List<String> words;
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.dragChipSpacing,
      runSpacing: AppDimensions.dragChipSpacing,
      children: [
        for (var index = 0; index < words.length; index++)
          GestureDetector(
            key: ValueKey(index),
            onTap: () => onToggle(index),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.dragChipPadding),
              decoration: BoxDecoration(
                color: selectedIndices.contains(index)
                    ? AppColors.wordSelectedBackground
                    : AppColors.wordUnselectedBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Text(words[index]),
            ),
          ),
      ],
    );
  }
}
