import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import '../../constants/reading_strings.dart';
import 'drag_blank_border.dart';

class _DraggedWord {
  const _DraggedWord(this.option, [this.fromGap]);
  final TaskOption option;
  final int? fromGap;
}

/// Same passage and word bank for candidates and preview. Callers retain
/// ownership of positional answer values and persistence.
class InlineDragDropPassage extends StatelessWidget {
  const InlineDragDropPassage({
    super.key,
    required this.promptText,
    required this.options,
    required this.assignments,
    required this.onAssign,
    required this.onClear,
  });
  final String promptText;
  final List<TaskOption> options;
  final Map<int, TaskOption> assignments;
  final void Function(int index, TaskOption option) onAssign;
  final ValueChanged<int> onClear;

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
            indices.every((index) => index >= 1 && index <= indices.length)
        ? 1
        : 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = AppDimensions.dragBlankMinWidth;
        for (final option in options) {
          final painter = TextPainter(
            text: TextSpan(text: option.text, style: AppTypography.examAnswer),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          width = math.max(width, painter.width + AppDimensions.spacingLg);
          painter.dispose();
        }
        width = math.min(width, AppDimensions.dragBlankMaxWidth);
        if (constraints.hasBoundedWidth) {
          width = math.min(
            width,
            math.max(1, constraints.maxWidth - AppDimensions.spacingSm),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              key: const ValueKey('dragDropPassage'),
              TextSpan(
                children: [
                  for (final segment in segments)
                    if (segment is PromptTextSegment)
                      TextSpan(text: segment.text)
                    else if (segment is PromptGapSegment)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: _gap(segment.gapIndex - offset, width),
                        ),
                      ),
                ],
              ),
              style: AppTypography.examAnswer.copyWith(
                height: 2.1,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            _bank(),
          ],
        );
      },
    );
  }

  Widget _gap(int index, double width) {
    final assigned = assignments[index];
    return DragTarget<_DraggedWord>(
      onWillAcceptWithDetails: (details) => options.any(
        (option) => option.orderIndex == details.data.option.orderIndex,
      ),
      onAcceptWithDetails: (details) => onAssign(index, details.data.option),
      builder: (context, candidates, rejected) {
        final box = Container(
          key: ValueKey('dragBlank-$index'),
          width: width,
          height: AppDimensions.dragBlankHeight,
          color: candidates.isNotEmpty
              ? AppColors.interactiveSelected
              : AppColors.surface,
          child: CustomPaint(
            painter: DragBlankBorder(highlighted: candidates.isNotEmpty),
            child: Center(
              child: assigned == null
                  ? null
                  : Text(
                      assigned.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.examAnswer.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ),
        );
        return Semantics(
          label: ReadingStrings.dragGapLabel(index, assigned?.text),
          child: assigned == null
              ? box
              : Draggable<_DraggedWord>(
                  data: _DraggedWord(assigned, index),
                  feedback: Material(
                    color: Colors.transparent,
                    child: _chip(assigned),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: box),
                  child: box,
                ),
        );
      },
    );
  }

  Widget _bank() {
    final used = assignments.values.map((option) => option.orderIndex).toSet();
    return DragTarget<_DraggedWord>(
      onWillAcceptWithDetails: (details) => details.data.fromGap != null,
      onAcceptWithDetails: (details) {
        final gap = details.data.fromGap;
        if (gap != null) onClear(gap);
      },
      builder: (context, candidates, rejected) => Container(
        key: const ValueKey('dragWordBank'),
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: AppDimensions.dragWordBankMinHeight,
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.interactiveHighlight,
          border: Border.all(
            color: candidates.isEmpty
                ? AppColors.borderSubtle
                : AppColors.brandPrimary,
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppDimensions.dragChipSpacing,
          runSpacing: AppDimensions.dragChipSpacing,
          children: [
            for (final option in options)
              if (!used.contains(option.orderIndex))
                Semantics(
                  key: ValueKey('dragWord-${option.orderIndex}'),
                  label: ReadingStrings.dragWordLabel(option.text),
                  child: Draggable<_DraggedWord>(
                    data: _DraggedWord(option),
                    feedback: Material(
                      color: Colors.transparent,
                      child: _chip(option),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _chip(option),
                    ),
                    child: _chip(option),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _chip(TaskOption option) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.drag_indicator,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Flexible(
          child: Text(
            option.text,
            style: AppTypography.examAnswer.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );
}
