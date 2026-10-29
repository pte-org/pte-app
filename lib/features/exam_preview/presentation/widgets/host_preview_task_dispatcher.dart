import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/templates/exam_template_frame.dart';
import 'package:pte_app/core/widgets/templates/fill_blanks_template.dart';
import 'package:pte_app/core/widgets/templates/free_text_template.dart';
import 'package:pte_app/core/widgets/templates/multi_select_template.dart';
import 'package:pte_app/core/widgets/templates/ordering_template.dart';
import 'package:pte_app/core/widgets/templates/record_response_template.dart';
import 'package:pte_app/core/widgets/templates/single_select_template.dart';
import 'package:pte_app/core/widgets/templates/token_toggle_template.dart';

import '../model/preview_task_ui_model.dart';
import 'preview_media_status.dart';
import 'host_preview_stimulus.dart';
import 'host_preview_response.dart';

class HostPreviewTaskDispatcher extends StatelessWidget {
  const HostPreviewTaskDispatcher({
    super.key,
    required this.model,
    required this.answer,
    required this.onAnswerChanged,
    this.onAudioPressed,
    this.onStartRecording,
    this.onStopRecording,
    this.isRecording = false,
  });

  final PreviewTaskUiModel model;
  final Object? answer;
  final ValueChanged<Object?> onAnswerChanged;
  final VoidCallback? onAudioPressed;
  final Future<void> Function()? onStartRecording;
  final Future<void> Function()? onStopRecording;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    if (!model.isSupported) {
      return PreviewMediaStatus(
        title: ExamPreviewStrings.unsupportedTitle,
        message: ExamPreviewStrings.unsupportedTask(
          model.resolution.identifier,
        ),
        isError: true,
      );
    }
    final stimulus = HostPreviewStimulus(
      model: model,
      onAudioPressed: onAudioPressed,
    );
    final response = HostPreviewResponse(
      key: ValueKey(model.item.snapshotItemPublicId),
      model: model,
      answer: answer,
      onAnswerChanged: onAnswerChanged,
      onStartRecording: onStartRecording,
      onStopRecording: onStopRecording,
      isRecording: isRecording,
    );
    final metadata = _metadata(model);
    final title = model.title;
    final subtitle = model.item.section;
    final instruction = model.instruction;
    return switch (model.meta!.family) {
      TaskTemplateFamily.recordResponse => RecordResponseTemplate(
        title: title,
        subtitle: subtitle,
        instruction: instruction,
        stimulus: stimulus,
        response: response,
        metadata: metadata,
        layout: model.taskType == TaskTypeCodes.readAloud
            ? ExamTemplateLayout.centeredResponse
            : ExamTemplateLayout.split,
      ),
      TaskTemplateFamily.freeText => FreeTextTemplate(
        title: title,
        subtitle: subtitle,
        instruction: instruction,
        stimulus: stimulus,
        response: response,
        metadata: metadata,
      ),
      TaskTemplateFamily.singleSelect => SingleSelectTemplate(
        title: title,
        subtitle: subtitle,
        instruction: instruction,
        stimulus: stimulus,
        response: response,
        metadata: metadata,
        readingLayout: model.item.section == 'READING',
      ),
      TaskTemplateFamily.multiSelect => MultiSelectTemplate(
        title: title,
        subtitle: subtitle,
        instruction: instruction,
        stimulus: stimulus,
        response: response,
        metadata: metadata,
        maxWidth: _maxWidth(model),
      ),
      TaskTemplateFamily.fillBlanks => FillBlanksTemplate(
        title: title,
        subtitle: subtitle,
        instruction: instruction,
        stimulus: stimulus,
        response: response,
        metadata: metadata,
        maxWidth: _maxWidth(model),
      ),
      TaskTemplateFamily.ordering => OrderingTemplate(
        title: title,
        subtitle: subtitle,
        instruction: instruction,
        stimulus: stimulus,
        response: response,
        metadata: metadata,
        maxWidth: _maxWidth(model),
      ),
      TaskTemplateFamily.tokenToggle => TokenToggleTemplate(
        title: title,
        subtitle: subtitle,
        instruction: instruction,
        stimulus: stimulus,
        response: response,
        metadata: metadata,
        maxWidth: _maxWidth(model),
      ),
    };
  }

  double _maxWidth(PreviewTaskUiModel model) => model.item.section == 'READING'
      ? AppDimensions.readingWorkstationMaxWidth
      : AppDimensions.contentMaxWidth;

  List<String> _metadata(PreviewTaskUiModel model) {
    final values = <String>[];
    if (model.item.prepSeconds > 0 || model.item.responseSeconds > 0) {
      values.add(
        ExamPreviewStrings.taskTiming(
          model.item.prepSeconds,
          model.item.responseSeconds,
        ),
      );
    }
    final min = model.item.minWordCount;
    final max = model.item.maxWordCount;
    if (min != null || max != null) {
      values.add(ExamPreviewStrings.wordBounds(min, max));
    }
    values.add(ExamPreviewStrings.previewOnly);
    return values;
  }
}
