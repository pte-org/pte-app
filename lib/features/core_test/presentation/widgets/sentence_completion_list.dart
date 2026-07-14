import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/inline_dropdown.dart';

/// Renders a list of sentences, each with an inline dropdown at the blank.
/// The dropdown flows and wraps within the sentence text via [WidgetSpan].
///
/// [preTexts] and [postTexts] are parallel lists: entry `i` is the text before
/// and after the blank of sentence `i` (`post` may be empty).
class SentenceCompletionList extends StatelessWidget {
  final List<String> preTexts;
  final List<String> postTexts;
  final List<String> wordBank;
  final Map<int, String?> answers;
  final void Function(int index, String? value) onAnswerChanged;

  const SentenceCompletionList({
    super.key,
    required this.preTexts,
    required this.postTexts,
    required this.wordBank,
    required this.answers,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < preTexts.length; i++) ...[
          _SentenceRow(
            pre: preTexts[i],
            post: postTexts[i],
            options: wordBank,
            value: answers[i],
            onChanged: (value) => onAnswerChanged(i, value),
          ),
          if (i < preTexts.length - 1)
            const SizedBox(height: AppDimensions.sentenceRowGap),
        ],
      ],
    );
  }
}

class _SentenceRow extends StatelessWidget {
  final String pre;
  final String post;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _SentenceRow({
    required this.pre,
    required this.post,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.sentenceText,
        children: [
          TextSpan(text: pre),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InlineDropdown(
              options: options,
              value: value,
              onChanged: onChanged,
            ),
          ),
          TextSpan(text: post),
        ],
      ),
    );
  }
}
