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
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_response.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_stimulus.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/exam_task_ui_model.dart';

class ExamUiPreviewTaskBody extends StatelessWidget {
  const ExamUiPreviewTaskBody({
    super.key,
    required this.model,
    this.audioLabel,
    this.onAudioPressed,
    this.audioPlaying = false,
    this.audioProgress = 0,
  });

  final ExamTaskUiModel model;
  final String? audioLabel;
  final VoidCallback? onAudioPressed;
  final bool audioPlaying;
  final double audioProgress;

  @override
  Widget build(BuildContext context) {
    final stimulus = ExamUiPreviewStimulus(
      model: model,
      audioLabel: audioLabel,
      onAudioPressed: onAudioPressed,
      audioPlaying: audioPlaying,
      audioProgress: audioProgress,
    );
    final response = ExamUiPreviewResponse(model: model);
    final metadata = _metadata(model);
    final title = model.meta.title;
    final subtitle = model.section;
    final instruction = model.instruction;

    return switch (model.meta.family) {
      TaskTemplateFamily.recordResponse => RecordResponseTemplate(
        title: title,
        subtitle: subtitle,
        instruction: instruction,
        stimulus: stimulus,
        response: response,
        metadata: metadata,
        layout: model.taskType == 'READ_ALOUD'
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
        readingLayout: model.section == 'READING',
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

  double _maxWidth(ExamTaskUiModel model) {
    return model.section == 'READING'
        ? AppDimensions.readingWorkstationMaxWidth
        : AppDimensions.contentMaxWidth;
  }

  List<String> _metadata(ExamTaskUiModel model) {
    final metadata = <String>[];
    if (model.prepSeconds > 0) {
      metadata.add(
        'Prep: ${model.prepSeconds}s | Response: ${model.responseSeconds}s',
      );
    }
    final min = model.minWordCount;
    final max = model.maxWordCount;
    if (min != null || max != null) {
      metadata.add('${min ?? 0}–${max ?? '∞'} words');
    }
    metadata.add('Scoring: ${model.meta.scoringMode}');
    return metadata;
  }
}
