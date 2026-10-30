import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';
import 'exam_template_frame.dart';
import 'read_aloud_template.dart';

/// Shared layout selection for snapshot previews and offline task previews.
/// State, media handling and response controls are injected by each caller.
class TaskTemplateBody extends StatelessWidget {
  const TaskTemplateBody({
    super.key,
    required this.taskType,
    required this.family,
    required this.title,
    required this.section,
    required this.instruction,
    required this.stimulus,
    required this.stimulusBuilder,
    required this.response,
    this.metadata = const [],
    this.hasSupplementaryContentOverride,
  });

  final String taskType;
  final TaskTemplateFamily family;
  final String title;
  final String section;
  final String instruction;
  final StimulusSpec stimulus;
  // null: all parts, true: images, false: all non-image parts.
  final Widget Function(bool? imageOnly) stimulusBuilder;
  final Widget response;
  final List<String> metadata;
  final bool? hasSupplementaryContentOverride;

  @override
  Widget build(BuildContext context) {
    final canonicalTaskType = TaskTypeCodes.canonicalize(taskType);
    final taskMeta = canonicalTaskType == null
        ? null
        : TaskTypeMeta.forTaskType(canonicalTaskType);
    final sectionTitle = taskMeta?.title ?? title;
    if (canonicalTaskType == TaskTypeCodes.readAloud) {
      return ReadAloudTemplate(
        title: sectionTitle,
        instruction: instruction,
        recorder: response,
        passage: stimulusBuilder(null),
      );
    }
    final recording = family == TaskTemplateFamily.recordResponse;
    final splitImages =
        recording &&
        stimulus.parts.any((part) => part.kind == StimulusPartKind.image);
    final hasSupplementaryContent =
        hasSupplementaryContentOverride ??
        stimulus.parts.any((part) => part.kind != StimulusPartKind.image);
    return ExamTemplateFrame(
      title: sectionTitle,
      subtitle: section,
      instruction: instruction,
      metadata: metadata,
      maxWidth:
          !recording &&
              family != TaskTemplateFamily.freeText &&
              section == 'READING'
          ? AppDimensions.readingWorkstationMaxWidth
          : double.infinity,
      layout: recording
          ? (splitImages
                ? ExamTemplateLayout.split
                : ExamTemplateLayout.centeredMedia)
          : ExamTemplateLayout.stacked,
      stimulus: stimulusBuilder(splitImages ? true : null),
      response: splitImages && hasSupplementaryContent
          ? Column(
              children: [
                stimulusBuilder(false),
                const SizedBox(height: AppDimensions.spacingLg),
                response,
              ],
            )
          : response,
    );
  }
}
