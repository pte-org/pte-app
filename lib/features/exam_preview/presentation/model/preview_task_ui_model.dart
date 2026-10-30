import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';

import '../../domain/entities/preview_snapshot.dart';
import 'package:pte_app/core/utils/task_instruction_resolver.dart';

class PreviewTaskUiModel {
  const PreviewTaskUiModel({
    required this.item,
    required this.meta,
    required this.resolution,
    required this.stimulus,
    required this.blankGroups,
  });

  final PreviewItem item;
  final TaskTypeMeta? meta;
  final TaskTypeResolution resolution;
  final StimulusSpec stimulus;
  final List<PreviewBlankGroup> blankGroups;

  bool get isSupported => resolution.isSupported && meta != null;

  String get title => item.title?.trim().isNotEmpty == true
      ? item.title!.trim()
      : meta?.title ??
            item.taskTypeDisplayName ??
            item.taskTypeCode ??
            ExamPreviewStrings.taskTitle;

  String get instruction => resolveTaskInstruction(
    apiInstruction: item.taskTypeInstruction,
    meta: meta,
    fallback: ExamPreviewStrings.defaultInstruction,
  );

  String get taskType =>
      item.taskTypeCode ?? item.taskType ?? 'UNKNOWN_TASK_TYPE';
}

class PreviewBlankGroup {
  const PreviewBlankGroup({required this.blankIndex, required this.options});

  final int blankIndex;
  final List<String> options;
}
