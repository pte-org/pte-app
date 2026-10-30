import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/widgets/components/highlightable_word_span.dart';

/// One bordered transcript with clickable words. Word IDs are whitespace-token
/// positions, independent of line wrapping; punctuation stays with its word.
class WordSelectionList extends StatelessWidget {
  const WordSelectionList({
    super.key,
    required this.words,
    required this.selectedIndices,
    required this.onToggle,
    this.transcript,
  });
  final List<String> words;
  final String? transcript;
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in RegExp(
      r'\s+|\S+',
    ).allMatches(transcript ?? words.join(' '))) {
      final token = match.group(0)!;
      if (token.trim().isEmpty) {
        spans.add(TextSpan(text: token));
      } else {
        final wordIndex = index++;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: HighlightableWordSpan(
              key: ValueKey('highlight-word-$wordIndex'),
              word: token,
              highlighted: selectedIndices.contains(wordIndex),
              onTap: () => onToggle(wordIndex),
            ),
          ),
        );
      }
    }
    return Container(
      key: const ValueKey('highlightTranscriptFrame'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text.rich(
        TextSpan(children: spans),
        key: const ValueKey('highlightTranscriptPassage'),
        style: AppTypography.examAnswer,
      ),
    );
  }
}
