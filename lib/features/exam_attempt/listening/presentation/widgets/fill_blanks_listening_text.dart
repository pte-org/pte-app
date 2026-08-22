import 'package:flutter/material.dart';

import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/fill_blanks_input_widget.dart';

/// Passage with inline free-type-in gaps — reuses `parseBlankPrompt`
/// (Reading's `{{n}}` marker parser, unmodified) but renders a
/// `TextField` per gap instead of a drag target or dropdown (phase-05
/// Design Constraints). [controllers] is index-aligned to gap index and
/// owned by the screen.
class FillBlanksListeningText extends StatelessWidget {
  const FillBlanksListeningText({super.key, required this.promptText, required this.controllers});

  final String promptText;
  final List<TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final segments = parseBlankPrompt(promptText);
    return Text.rich(TextSpan(children: [for (final segment in segments) _spanFor(segment)]));
  }

  InlineSpan _spanFor(PromptSegment segment) {
    if (segment is PromptTextSegment) {
      return TextSpan(text: segment.text);
    }
    final gapIndex = (segment as PromptGapSegment).gapIndex;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: FillBlanksInputWidget(controller: controllers[gapIndex]),
    );
  }
}
