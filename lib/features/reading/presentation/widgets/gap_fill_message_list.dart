import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/inline_dropdown.dart';

/// The body of the gap-fill message: one line per gap, each an inline dropdown
/// flowing within the sentence text. The line at [fixedIndex] is pre-filled and
/// locked ("the first one is done for you").
class GapFillMessageList extends StatelessWidget {
  final List<String> preTexts;
  final List<String> postTexts;
  final List<List<String>> optionsList;
  final Map<int, String?> answers;
  final int fixedIndex;
  final void Function(int index, String? value) onAnswerChanged;

  const GapFillMessageList({
    super.key,
    required this.preTexts,
    required this.postTexts,
    required this.optionsList,
    required this.answers,
    required this.fixedIndex,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < preTexts.length; i++) ...[
          _MessageLine(
            pre: preTexts[i],
            post: postTexts[i],
            options: optionsList[i],
            value: answers[i],
            locked: i == fixedIndex,
            onChanged: (value) => onAnswerChanged(i, value),
          ),
          if (i < preTexts.length - 1)
            const SizedBox(height: AppDimensions.readingMessageLineGap),
        ],
      ],
    );
  }
}

class _MessageLine extends StatelessWidget {
  final String pre;
  final String post;
  final List<String> options;
  final String? value;
  final bool locked;
  final ValueChanged<String?> onChanged;

  const _MessageLine({
    required this.pre,
    required this.post,
    required this.options,
    required this.value,
    required this.locked,
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
              onChanged: locked ? null : onChanged,
            ),
          ),
          TextSpan(text: post),
        ],
      ),
    );
  }
}
