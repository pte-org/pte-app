import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/components/choice_list.dart';
import 'package:pte_app/core/widgets/components/choice_row.dart';
import 'package:pte_app/core/widgets/components/exam_status_block.dart';
import 'package:pte_app/core/widgets/components/exam_textarea.dart';
import 'package:pte_app/core/widgets/components/fill_blank_chip.dart';
import 'package:pte_app/core/widgets/components/highlightable_word_span.dart';
import 'package:pte_app/core/widgets/components/record_response_card.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/exam_task_ui_model.dart';
import 'package:pte_app/features/exam_attempt/domain/word_count.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/text_editor_toolbar.dart';

class ExamUiPreviewResponse extends StatefulWidget {
  const ExamUiPreviewResponse({super.key, required this.model});

  final ExamTaskUiModel model;

  @override
  State<ExamUiPreviewResponse> createState() => _ExamUiPreviewResponseState();
}

class _ExamUiPreviewResponseState extends State<ExamUiPreviewResponse> {
  late final TextEditingController _controller;
  final Set<int> _selected = {};
  final Set<int> _highlighted = {};

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    if (model.meta.family == TaskTemplateFamily.recordResponse) {
      return Column(
        children: [
          RecordResponseCard(
            prepSeconds: model.prepSeconds,
            responseSeconds: model.responseSeconds,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const ExamStatusBlock(
            title: 'Microphone Guidelines',
            message:
                'Speak clearly and continually after the tone. The recording stops automatically when time expires.',
          ),
        ],
      );
    }
    if (model.meta.family == TaskTemplateFamily.freeText) {
      return Column(
        children: [
          TextEditorToolbar(controller: _controller),
          ExamTextarea(controller: _controller),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) => Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${countWords(value.text)} words',
                style: AppTypography.labelMeta.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const ExamStatusBlock(
            title: 'Response draft',
            message: 'Typing is local to this preview and is never submitted.',
          ),
        ],
      );
    }
    if (model.meta.family == TaskTemplateFamily.singleSelect ||
        model.meta.family == TaskTemplateFamily.multiSelect) {
      return ChoiceList(
        labels: [for (final option in model.options) option.text],
        selectedIndices: _selected,
        mode: model.meta.family == TaskTemplateFamily.multiSelect
            ? ChoiceSelectionMode.multiple
            : ChoiceSelectionMode.single,
        onTap: (index) => setState(() {
          if (model.meta.family == TaskTemplateFamily.singleSelect) {
            _selected
              ..clear()
              ..add(index);
          } else if (!_selected.add(index)) {
            _selected.remove(index);
          }
        }),
      );
    }
    if (model.meta.family == TaskTemplateFamily.tokenToggle) {
      final words = model.stimulus.parts
          .expand((part) => part.content.split(RegExp(r'\s+')))
          .where((word) => word.isNotEmpty)
          .toList();
      return Wrap(
        spacing: AppDimensions.spacingSm,
        runSpacing: AppDimensions.spacingXs,
        children: [
          for (var index = 0; index < words.length; index++)
            HighlightableWordSpan(
              word: words[index],
              highlighted: _highlighted.contains(index),
              onTap: () => setState(() {
                if (!_highlighted.add(index)) _highlighted.remove(index);
              }),
            ),
        ],
      );
    }
    if (model.meta.family == TaskTemplateFamily.ordering) {
      return Column(
        children: [
          for (var index = 0; index < model.options.length; index++)
            ListTile(
              tileColor: AppColors.surfaceSubtle,
              leading: Text('${index + 1}'),
              title: Text(model.options[index].text),
              trailing: const Icon(Icons.drag_handle),
            ),
        ],
      );
    }
    if (model.blankGroups.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in model.blankGroups) ...[
            Text('Blank ${group.blankIndex + 1}'),
            const SizedBox(height: AppDimensions.spacingXs),
            Wrap(
              spacing: AppDimensions.spacingSm,
              runSpacing: AppDimensions.spacingSm,
              children: [
                for (final option in group.options)
                  FillBlankChip(label: option.text, onTap: () {}),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
        ],
      );
    }
    if (model.options.isEmpty) {
      return ExamTextarea(controller: _controller, minLines: 4);
    }
    return Wrap(
      spacing: AppDimensions.spacingSm,
      runSpacing: AppDimensions.spacingSm,
      children: [
        for (final option in model.options)
          FillBlankChip(label: option.text, onTap: () {}),
      ],
    );
  }
}
