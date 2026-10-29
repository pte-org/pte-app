import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';
import '../model/preview_task_ui_model.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/components/choice_list.dart';
import 'package:pte_app/core/widgets/components/choice_row.dart';
import 'package:pte_app/core/widgets/components/exam_textarea.dart';
import 'package:pte_app/core/widgets/components/highlightable_word_span.dart';
import 'package:pte_app/core/widgets/components/record_response_card.dart';
import 'preview_media_status.dart';
import 'host_preview_ordering_response.dart';
import 'host_preview_fill_blanks_response.dart';

class HostPreviewResponse extends StatefulWidget {
  const HostPreviewResponse({
    super.key,
    required this.model,
    required this.answer,
    required this.onAnswerChanged,
    this.onStartRecording,
    this.onStopRecording,
    this.isRecording = false,
  });

  final PreviewTaskUiModel model;
  final Object? answer;
  final ValueChanged<Object?> onAnswerChanged;
  final Future<void> Function()? onStartRecording;
  final Future<void> Function()? onStopRecording;
  final bool isRecording;

  @override
  State<HostPreviewResponse> createState() => HostPreviewResponseState();
}

class HostPreviewResponseState extends State<HostPreviewResponse> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _textAnswer);
  }

  @override
  void didUpdateWidget(covariant HostPreviewResponse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.item.snapshotItemPublicId !=
        widget.model.item.snapshotItemPublicId) {
      _textController.text = _textAnswer;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _textAnswer =>
      widget.answer is String ? widget.answer as String : '';

  @override
  Widget build(BuildContext context) {
    final family = widget.model.meta!.family;
    if (family == TaskTemplateFamily.recordResponse) {
      return Column(
        children: [
          RecordResponseCard(
            prepSeconds: widget.model.item.prepSeconds,
            responseSeconds: widget.model.item.responseSeconds,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      widget.isRecording || widget.onStartRecording == null
                      ? null
                      : () => widget.onStartRecording!(),
                  icon: const Icon(Icons.mic_none),
                  label: const Text(ExamPreviewStrings.startRecording),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      widget.isRecording && widget.onStopRecording != null
                      ? () => widget.onStopRecording!()
                      : null,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text(ExamPreviewStrings.stopRecording),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const PreviewMediaStatus(
            title: ExamPreviewStrings.recordingTitle,
            message: ExamPreviewStrings.recordingMessage,
          ),
        ],
      );
    }
    if (family == TaskTemplateFamily.freeText) {
      return Column(
        children: [
          ExamTextarea(
            controller: _textController,
            labelText: ExamPreviewStrings.responseLabel,
            onChanged: widget.onAnswerChanged,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              ExamPreviewStrings.wordCount(_textController.text),
              style: AppTypography.labelMeta.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const PreviewMediaStatus(
            title: ExamPreviewStrings.draftTitle,
            message: ExamPreviewStrings.draftMessage,
          ),
        ],
      );
    }
    if (family == TaskTemplateFamily.singleSelect ||
        family == TaskTemplateFamily.multiSelect) {
      final selected = _asIntSet(widget.answer);
      return ChoiceList(
        labels: [for (final option in widget.model.item.options) option.text],
        selectedIndices: selected,
        mode: family == TaskTemplateFamily.multiSelect
            ? ChoiceSelectionMode.multiple
            : ChoiceSelectionMode.single,
        onTap: (index) {
          if (family == TaskTemplateFamily.singleSelect) {
            widget.onAnswerChanged(<int>[index]);
          } else {
            final next = {...selected};
            if (!next.add(index)) next.remove(index);
            widget.onAnswerChanged(next.toList()..sort());
          }
        },
      );
    }
    if (family == TaskTemplateFamily.tokenToggle) {
      final selected = _asIntSet(widget.answer);
      final words = _words(widget.model.item.promptText);
      return Wrap(
        spacing: AppDimensions.spacingSm,
        runSpacing: AppDimensions.spacingXs,
        children: [
          for (var index = 0; index < words.length; index++)
            HighlightableWordSpan(
              word: words[index],
              highlighted: selected.contains(index),
              onTap: () {
                final next = {...selected};
                if (!next.add(index)) next.remove(index);
                widget.onAnswerChanged(next.toList()..sort());
              },
            ),
        ],
      );
    }
    if (family == TaskTemplateFamily.ordering) {
      return HostPreviewOrderingResponse(
        model: widget.model,
        answer: widget.answer,
        onChanged: widget.onAnswerChanged,
      );
    }
    if (family == TaskTemplateFamily.fillBlanks) {
      return HostPreviewFillBlanksResponse(
        model: widget.model,
        answer: widget.answer,
        onChanged: widget.onAnswerChanged,
      );
    }
    return const PreviewMediaStatus(
      title: ExamPreviewStrings.responseErrorTitle,
      message: ExamPreviewStrings.responseErrorMessage,
      isError: true,
    );
  }

  Set<int> _asIntSet(Object? value) => value is Iterable
      ? value.whereType<num>().map((number) => number.toInt()).toSet()
      : <int>{};

  List<String> _words(String? value) => (value ?? '')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
}
