import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';

enum DataOrigin { api, fixture, derived, unavailable }

class ExamTaskUiOption {
  const ExamTaskUiOption({required this.text, required this.orderIndex});

  final String text;
  final String orderIndex;
}

class ExamTaskUiBlankGroup {
  const ExamTaskUiBlankGroup({required this.blankIndex, required this.options});

  final int blankIndex;
  final List<ExamTaskUiOption> options;
}

/// Presentation model built at the feature boundary. It intentionally keeps
/// provenance so a missing API field cannot silently become preview content.
class ExamTaskUiModel {
  const ExamTaskUiModel({
    required this.taskType,
    required this.meta,
    required this.title,
    required this.section,
    required this.instruction,
    required this.stimulus,
    required this.options,
    required this.blankGroups,
    required this.prepSeconds,
    required this.responseSeconds,
    required this.minWordCount,
    required this.maxWordCount,
    required this.origin,
  });

  final String taskType;
  final TaskTypeMeta meta;
  final String title;
  final String section;
  final String instruction;
  final StimulusSpec stimulus;
  final List<ExamTaskUiOption> options;
  final List<ExamTaskUiBlankGroup> blankGroups;
  final int prepSeconds;
  final int responseSeconds;
  final int? minWordCount;
  final int? maxWordCount;
  final DataOrigin origin;

  bool get hasResponseContent => options.isNotEmpty || blankGroups.isNotEmpty;

  bool get isComplete {
    final hasContent =
        !stimulus.isEmpty ||
        hasResponseContent ||
        meta.family == TaskTemplateFamily.recordResponse;
    return title.trim().isNotEmpty &&
        instruction.trim().isNotEmpty &&
        hasContent;
  }
}
