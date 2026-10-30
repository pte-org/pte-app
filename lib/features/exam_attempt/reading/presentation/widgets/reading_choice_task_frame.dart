import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/widgets/templates/exam_task_frame.dart';

/// Reading imports append the question after a blank line in promptText.
/// Keep ordinary passage paragraphs intact when no question is identifiable.
class ReadingChoiceTaskFrame extends StatelessWidget {
  const ReadingChoiceTaskFrame({
    super.key,
    required this.title,
    required this.instruction,
    required this.promptText,
    required this.response,
  });

  final String title;
  final String instruction;
  final String? promptText;
  final Widget response;

  @override
  Widget build(BuildContext context) {
    final prompt = (promptText ?? '').replaceAll('\r\n', '\n').trim();
    final separator = prompt.lastIndexOf('\n\n');
    final tail = separator < 0 ? '' : prompt.substring(separator + 2).trim();
    final hasQuestion =
        tail.isNotEmpty &&
        (tail.endsWith('?') ||
            RegExp(
              r'^(Which|What|According|Choose|Select)\b',
              caseSensitive: false,
            ).hasMatch(tail));
    final passage = hasQuestion
        ? prompt.substring(0, separator).trim()
        : prompt;
    final question = hasQuestion ? tail : '';
    return ExamTaskFrame(
      title: title,
      instruction: '',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final left = Text(
            passage,
            key: const ValueKey('readingChoicePassage'),
            style: AppTypography.examAnswer,
          );
          final right = Column(
            key: const ValueKey('readingChoiceResponse'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                instruction,
                style: AppTypography.instructionBold.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              if (question.isNotEmpty) ...[
                Text(question, style: AppTypography.examAnswer),
                const SizedBox(height: AppDimensions.spacingLg),
              ],
              response,
            ],
          );
          if (constraints.maxWidth <
              AppDimensions.templateSideBySideBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                left,
                const SizedBox(height: AppDimensions.spacingLg),
                right,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppDimensions.spacingXl),
              Expanded(child: right),
            ],
          );
        },
      ),
    );
  }
}
