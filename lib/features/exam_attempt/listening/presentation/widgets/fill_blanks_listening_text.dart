import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import '../../constants/listening_strings.dart';
import 'fill_blanks_input_widget.dart';

/// One shared inline passage for student delivery and host preview.
/// Marker numbers may start at zero or one; answer indices remain zero-based.
class FillBlanksListeningText extends StatelessWidget {
  const FillBlanksListeningText({
    super.key,
    required this.promptText,
    required this.controllers,
  });
  final String promptText;
  final List<TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final segments = parseBlankPrompt(promptText);
    final indices = segments
        .whereType<PromptGapSegment>()
        .map((gap) => gap.gapIndex)
        .toList();
    final offset =
        indices.isNotEmpty &&
            !indices.contains(0) &&
            indices.every((index) => index >= 1 && index <= controllers.length)
        ? 1
        : 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? math.min(
                AppDimensions.listeningBlankWidth,
                math.max(1.0, constraints.maxWidth - 8),
              )
            : AppDimensions.listeningBlankWidth;
        return Text.rich(
          key: const ValueKey('typeInPassage'),
          TextSpan(
            children: [
              for (final segment in segments)
                if (segment is PromptTextSegment)
                  TextSpan(text: segment.text)
                else if (segment is PromptGapSegment)
                  _gap(segment.gapIndex - offset, width),
            ],
          ),
          style: AppTypography.examAnswer.copyWith(height: 2.1),
        );
      },
    );
  }

  InlineSpan _gap(int index, double width) {
    if (index < 0 || index >= controllers.length) return const TextSpan();
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Semantics(
          label: ListeningStrings.blankLabel(index + 1),
          child: FillBlanksInputWidget(
            key: ValueKey('typeInBlank-$index'),
            controller: controllers[index],
            width: width,
          ),
        ),
      ),
    );
  }
}
