import 'package:flutter/material.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/paragraph_source_target.dart';
import '../model/preview_task_ui_model.dart';

class HostPreviewOrderingResponse extends StatelessWidget {
  const HostPreviewOrderingResponse({
    super.key,
    required this.model,
    required this.answer,
    required this.onChanged,
  });
  final PreviewTaskUiModel model;
  final Object? answer;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = model.item.options;
    final ids = answer is Iterable
        ? (answer as Iterable)
              .whereType<num>()
              .map((value) => value.toInt())
              .where((index) => index >= 0 && index < options.length)
              .toSet()
              .toList()
        : <int>[];
    return ParagraphSourceTarget(
      paragraphs: {
        for (var i = 0; i < options.length; i++) '$i': options[i].text,
      },
      targetIds: ids.map((id) => '$id').toList(),
      onChanged: (values) => onChanged(values.map(int.parse).toList()),
    );
  }
}
