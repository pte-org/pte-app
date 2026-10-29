import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';

import '../../domain/entities/preview_snapshot.dart';
import 'preview_task_ui_model.dart';

class PreviewTaskUiAdapter {
  const PreviewTaskUiAdapter._();

  static PreviewTaskUiModel adapt(PreviewItem item) {
    final resolution = TaskTypeRendererRegistry.resolve(
      taskTypeCode: item.taskTypeCode,
      legacyTaskType: item.taskType,
      runtime: item.runtime,
    );
    final meta =
        resolution.registration?.meta ??
        TaskTypeMeta.forTaskType(item.taskTypeCode ?? item.taskType ?? '');
    final parts = <StimulusPart>[];
    final prompt = item.promptText?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      parts.add(StimulusPart(kind: StimulusPartKind.text, content: prompt));
    }
    final imageUrl = item.imageUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      parts.add(StimulusPart(kind: StimulusPartKind.image, content: imageUrl));
    }
    final audioUrl = item.audioUrl?.trim();
    if (audioUrl != null && audioUrl.isNotEmpty) {
      parts.add(StimulusPart(kind: StimulusPartKind.audio, content: audioUrl));
    }
    final groups = <int, List<String>>{};
    for (final option in item.options) {
      final blankIndex = option.blankIndex;
      if (blankIndex != null) {
        groups.putIfAbsent(blankIndex, () => <String>[]).add(option.text);
      }
    }
    return PreviewTaskUiModel(
      item: item,
      meta: meta,
      resolution: resolution,
      stimulus: StimulusSpec(parts: List.unmodifiable(parts)),
      blankGroups: [
        for (final entry in groups.entries)
          PreviewBlankGroup(
            blankIndex: entry.key,
            options: List.unmodifiable(entry.value),
          ),
      ],
    );
  }
}
