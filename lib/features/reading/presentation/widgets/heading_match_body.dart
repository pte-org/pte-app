import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/inline_dropdown.dart';

/// Two-pane reading layout: a scrollable passage on the left and a column of
/// heading dropdowns on the right, split by a draggable vertical divider.
class HeadingMatchBody extends StatefulWidget {
  final String instruction;
  final String passageTitle;
  final List<String> paragraphs;
  final List<String> headingOptions;
  final Map<int, String?> answers;
  final void Function(int index, String? value) onAnswerChanged;

  const HeadingMatchBody({
    super.key,
    required this.instruction,
    required this.passageTitle,
    required this.paragraphs,
    required this.headingOptions,
    required this.answers,
    required this.onAnswerChanged,
  });

  @override
  State<HeadingMatchBody> createState() => _HeadingMatchBodyState();
}

class _HeadingMatchBodyState extends State<HeadingMatchBody> {
  double _leftFraction = AppDimensions.readingSplitDefaultLeftFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const divider = AppDimensions.readingSplitDividerWidth;
        const minPane = AppDimensions.readingSplitMinPaneWidth;
        final available = constraints.maxWidth - divider;
        final leftWidth = (available * _leftFraction)
            .clamp(minPane, available - minPane)
            .toDouble();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: leftWidth,
              child: _PassagePane(
                title: widget.passageTitle,
                paragraphs: widget.paragraphs,
              ),
            ),
            _SplitHandle(
              onDrag: (dx) => setState(() {
                final next = (leftWidth + dx)
                    .clamp(minPane, available - minPane)
                    .toDouble();
                _leftFraction = next / available;
              }),
            ),
            Expanded(
              child: _HeadingsPane(
                instruction: widget.instruction,
                options: widget.headingOptions,
                answers: widget.answers,
                onAnswerChanged: widget.onAnswerChanged,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PassagePane extends StatelessWidget {
  final String title;
  final List<String> paragraphs;

  const _PassagePane({required this.title, required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text(title, style: AppTextStyles.readingTitle)),
          const SizedBox(height: AppDimensions.readingPassageTitleGap),
          for (final paragraph in paragraphs) ...[
            Text(paragraph, style: AppTextStyles.sentenceText),
            const SizedBox(height: AppDimensions.readingPassageParagraphGap),
          ],
        ],
      ),
    );
  }
}

class _SplitHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;

  const _SplitHandle({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: AppDimensions.readingSplitDividerWidth,
          alignment: Alignment.center,
          child: Container(
            width: AppDimensions.readingSplitHandleWidth,
            color: AppColors.dividerGray,
          ),
        ),
      ),
    );
  }
}

class _HeadingsPane extends StatelessWidget {
  final String instruction;
  final List<String> options;
  final Map<int, String?> answers;
  final void Function(int index, String? value) onAnswerChanged;

  const _HeadingsPane({
    required this.instruction,
    required this.options,
    required this.answers,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(instruction, style: AppTextStyles.instruction),
          const SizedBox(height: AppDimensions.readingMessageBlockGap),
          for (int i = 0; i < answers.length; i++) ...[
            _HeadingRow(
              number: i + 1,
              options: options,
              value: answers[i],
              onChanged: (value) => onAnswerChanged(i, value),
            ),
            if (i < answers.length - 1)
              const SizedBox(height: AppDimensions.headingRowGap),
          ],
        ],
      ),
    );
  }
}

class _HeadingRow extends StatelessWidget {
  final int number;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _HeadingRow({
    required this.number,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: AppDimensions.headingNumberWidth,
          child: Text('$number.', style: AppTextStyles.sentenceText),
        ),
        Expanded(
          child: InlineDropdown(
            options: options,
            value: value,
            onChanged: onChanged,
            width: double.infinity,
            height: AppDimensions.headingDropdownHeight,
          ),
        ),
      ],
    );
  }
}
