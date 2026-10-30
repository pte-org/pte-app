import 'package:flutter/material.dart';
import 'package:pte_app/core/widgets/templates/task_template_body.dart';

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
    return TaskTemplateBody(
      taskType: model.taskType,
      family: model.meta.family,
      title: model.meta.title,
      section: model.section,
      instruction: model.instruction,
      stimulus: model.stimulus,
      metadata: _metadata(model),
      stimulusBuilder: (imageOnly) => ExamUiPreviewStimulus(
        model: model,
        imageOnly: imageOnly,
        audioLabel: audioLabel,
        onAudioPressed: onAudioPressed,
        audioPlaying: audioPlaying,
        audioProgress: audioProgress,
      ),
      response: ExamUiPreviewResponse(model: model),
    );
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
