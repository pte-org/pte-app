import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import '../../constants/reading_strings.dart';

import 'inline_blank_dropdown.dart';
export 'inline_blank_dropdown.dart' show InlineBlankChoice;

/// Shared passage renderer; answer values and persistence belong to the caller.
/// Handles both zero-based markers and one-based authoring markers paired with
/// zero-based answer groups without changing the answer payload indices.
class InlineBlankDropdownPassage extends StatelessWidget {
  const InlineBlankDropdownPassage({
    super.key,
    required this.promptText,
    required this.optionsByGap,
    required this.values,
    required this.onChanged,
  });

  final String promptText;
  final Map<int, List<InlineBlankChoice>> optionsByGap;
  final Map<int, String> values;
  final void Function(int gapIndex, String value) onChanged;

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
            optionsByGap.containsKey(0) &&
            indices.every((index) => index >= 1 && index <= optionsByGap.length)
        ? 1
        : 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Text.rich(
          TextSpan(
            children: [
              for (final segment in segments)
                if (segment is PromptTextSegment)
                  TextSpan(text: segment.text)
                else if (segment is PromptGapSegment)
                  _gap(
                    context,
                    segment.gapIndex - offset,
                    segment.gapIndex,
                    available,
                  ),
            ],
          ),
          key: const ValueKey('inlineBlankPassage'),
          style: AppTypography.bodyPassage.copyWith(
            color: AppColors.textPrimary,
          ),
        );
      },
    );
  }

  InlineSpan _gap(
    BuildContext context,
    int index,
    int marker,
    double available,
  ) {
    final options = optionsByGap[index];
    if (options == null || options.isEmpty) {
      return TextSpan(text: '{{$marker}}');
    }
    var width = AppDimensions.inlineBlankMinWidth;
    for (final option in options) {
      final painter = TextPainter(
        text: TextSpan(text: option.text, style: AppTypography.examAnswer),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      width = math.max(
        width,
        painter.width + AppDimensions.inlineBlankControlSpace,
      );
      painter.dispose();
    }
    width = math.min(
      width,
      math.min(
        AppDimensions.inlineBlankMaxWidth,
        math.max(1, available - AppDimensions.spacingXs),
      ),
    );
    final selected = options.any((option) => option.value == values[index])
        ? values[index]
        : null;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Semantics(
        label: ReadingStrings.inlineBlankLabel(index + 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXs / 2,
          ),
          child: InlineBlankDropdown(
            key: ValueKey('inlineBlank-$index'),
            width: width,
            options: options,
            value: selected,
            onChanged: (value) => onChanged(index, value),
          ),
        ),
      ),
    );
  }
}
