import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';
import '../model/preview_task_ui_model.dart';
import 'package:pte_app/core/widgets/components/fill_blank_chip.dart';
import 'package:pte_app/core/widgets/components/in_text_select.dart';

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
