import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/exam_task_ui_model.dart';

/// Converts the existing runtime task shape to design-system presentation data.
/// No API model or answer serialization is changed by this adapter.
class TaskViewUiAdapter {
  const TaskViewUiAdapter._();

  static ExamTaskUiModel adapt(
    TaskView task, {
    DataOrigin origin = DataOrigin.api,
  }) {
    final meta = TaskTypeMeta.forTaskType(task.taskType);
    if (meta == null) {
      throw ArgumentError.value(
        task.taskType,
        'task.taskType',
        'Unknown task type',
      );
    }

    final parts = <StimulusPart>[];
    const audioFallbackTypes = {
      'REPEAT_SENTENCE',
      'RE_TELL_LECTURE',
      'ANSWER_SHORT_QUESTION',
      'SUMMARIZE_GROUP_DISCUSSION',
      'RESPOND_TO_A_SITUATION',
    };
    final audioSource =
        task.audioPromptRef ??
        (origin == DataOrigin.fixture &&
                audioFallbackTypes.contains(task.taskType)
            ? 'assets/audio/listening_sample_summarize.wav'
            : null);
    if (audioSource != null) {
      parts.add(
        StimulusPart(
          kind: StimulusPartKind.audio,
          content: audioSource,
          label: 'Audio stimulus',
        ),
      );
    }
    final imageSource =
        task.imageUrl ??
        (origin == DataOrigin.fixture ? task.imagePromptRef : null);
    if (imageSource != null) {
      parts.add(
        StimulusPart(
          kind: StimulusPartKind.image,
          content: imageSource,
          label: 'Image stimulus',
        ),
      );
    }
    if (task.promptText?.trim().isNotEmpty == true) {
      parts.add(
        StimulusPart(
          kind: meta.section == 'READING'
              ? StimulusPartKind.passage
              : StimulusPartKind.text,
          content: task.promptText!,
          label: 'Task content',
        ),
      );
    }

    return ExamTaskUiModel(
      taskType: task.taskType,
      meta: meta,
      title: task.title.trim().isEmpty ? meta.title : task.title,
      section: task.section,
      instruction: meta.instruction,
      stimulus: StimulusSpec(parts: parts),
      options: [
        for (final option in task.options ?? const <TaskOption>[])
          ExamTaskUiOption(text: option.text, orderIndex: option.orderIndex),
      ],
      blankGroups: [
        for (final group in task.blankGroups ?? const <BlankGroup>[])
          ExamTaskUiBlankGroup(
            blankIndex: group.blankIndex,
            options: [
              for (final option in group.options)
                ExamTaskUiOption(
                  text: option.text,
                  orderIndex: option.orderIndex,
                ),
            ],
          ),
      ],
      prepSeconds: task.prepSeconds,
      responseSeconds: task.responseSeconds,
      minWordCount: task.minWordCount,
      maxWordCount: task.maxWordCount,
      origin: origin,
    );
  }
}
