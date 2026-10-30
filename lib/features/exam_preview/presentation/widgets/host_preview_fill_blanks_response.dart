import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/inline_blank_dropdown_passage.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';
import '../model/preview_task_ui_model.dart';
import 'package:pte_app/core/widgets/components/fill_blank_chip.dart';
import 'package:pte_app/core/widgets/components/in_text_select.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/inline_drag_drop_passage.dart';
import 'host_preview_type_in_response.dart';

class HostPreviewFillBlanksResponse extends StatelessWidget {
  const HostPreviewFillBlanksResponse({
    super.key,
    required this.model,
    required this.answer,
    required this.onChanged,
  });

  final PreviewTaskUiModel model;
  final Object? answer;
  final ValueChanged<Object?> onChanged;

  Map<int, String> get _values {
    final raw = answer;
    if (raw is! Map) return <int, String>{};
    return {
      for (final entry in raw.entries)
        if (entry.key is num && entry.value != null)
          (entry.key as num).toInt(): entry.value.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (TaskTypeCodes.canonicalize(model.taskType) ==
        TaskTypeCodes.fillInTheBlanksTypeIn) {
      return HostPreviewTypeInResponse(
        promptText: model.item.promptText ?? '',
        values: _values,
        onChanged: onChanged,
      );
    }
    if (TaskTypeCodes.canonicalize(model.taskType) ==
        TaskTypeCodes.fillInTheBlanksDragAndDrop) {
      final options = [
        for (final option in model.item.options)
          TaskOption(
            text: option.text,
            orderIndex: option.orderIndex.toString(),
          ),
      ];
      final byId = {for (final option in options) option.orderIndex: option};
      final values = _values;
      final assignments = <int, TaskOption>{};
      final used = <String>{};
      for (final entry in values.entries) {
        final option = byId[entry.value];
        if (option != null && used.add(option.orderIndex)) {
          assignments[entry.key] = option;
        }
      }
      return InlineDragDropPassage(
        promptText: model.item.promptText ?? '',
        options: options,
        assignments: assignments,
        onAssign: (index, option) {
          final next = {
            for (final entry in assignments.entries)
              if (entry.value.orderIndex != option.orderIndex)
                entry.key: entry.value.orderIndex,
          };
          next[index] = option.orderIndex;
          onChanged(next);
        },
        onClear: (index) => onChanged({...values}..remove(index)),
      );
    }
    if (TaskTypeCodes.canonicalize(model.taskType) ==
        TaskTypeCodes.fillInTheBlanksDropdown) {
      final values = _values;
      return InlineBlankDropdownPassage(
        promptText: model.item.promptText ?? '',
        optionsByGap: {
          for (final group in model.blankGroups)
            group.blankIndex: [
              for (final option in group.options.toSet())
                InlineBlankChoice(value: option, text: option),
            ],
        },
        values: values,
        onChanged: (index, value) => onChanged({...values, index: value}),
      );
    }
    if (model.blankGroups.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in model.item.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
              child: FillBlankChip(label: option.text, onTap: () {}),
            ),
        ],
      );
    }
    final values = _values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in model.blankGroups) ...[
          Text(ExamPreviewStrings.blankLabel(group.blankIndex + 1)),
          const SizedBox(height: AppDimensions.spacingXs),
          InTextSelect(
            options: group.options,
            value: values[group.blankIndex],
            onChanged: (value) {
              final next = {...values};
              if (value == null) {
                next.remove(group.blankIndex);
              } else {
                next[group.blankIndex] = value;
              }
              onChanged(next);
            },
          ),
          const SizedBox(height: AppDimensions.spacingMd),
        ],
      ],
    );
  }
}
