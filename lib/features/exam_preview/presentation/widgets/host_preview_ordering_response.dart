import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';
import '../model/preview_task_ui_model.dart';

class HostPreviewOrderingResponse extends StatefulWidget {
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
  State<HostPreviewOrderingResponse> createState() =>
      HostPreviewOrderingResponseState();
}

class HostPreviewOrderingResponseState
    extends State<HostPreviewOrderingResponse> {
  late List<int> _order;

  @override
  void initState() {
    super.initState();
    _order = _initialOrder;
  }

  List<int> get _initialOrder => widget.answer is Iterable
      ? (widget.answer as Iterable)
            .whereType<num>()
            .map((value) => value.toInt())
            .toList()
      : [
          for (var index = 0; index < widget.model.item.options.length; index++)
            index,
        ];

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _order.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final value = _order.removeAt(oldIndex);
          _order.insert(newIndex, value);
          widget.onChanged(List<int>.from(_order));
        });
      },
      itemBuilder: (context, index) {
        final optionIndex = _order[index];
        final label = optionIndex < widget.model.item.options.length
            ? widget.model.item.options[optionIndex].text
            : ExamPreviewStrings.optionLabel(optionIndex + 1);
        return ListTile(
          key: ValueKey('preview-order-$optionIndex'),
          tileColor: AppColors.surfaceSubtle,
          leading: Text('${index + 1}'),
          title: Text(label),
          trailing: const Icon(Icons.drag_handle),
        );
      },
    );
  }
}
