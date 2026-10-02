import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/features/exam_attempt/reading/constants/reading_strings.dart';

/// Maps a reading `TaskView.taskType` to its `ExamTaskHeaderBanner` title.
/// Unknown/non-reading types return an empty string — callers only invoke
/// this from the 5 reading task screens, which always pass a known type.
String readingTaskHeaderTitle(String taskType) {
  return switch (TaskTypeCodes.canonicalize(taskType)) {
    'MC_READING_SINGLE' => ReadingStrings.readingHeaderTitleMcSingle,
    'MC_READING_MULTIPLE' => ReadingStrings.readingHeaderTitleMcMultiple,
    'RE_ORDER_PARAGRAPHS' => ReadingStrings.readingHeaderTitleReorderParagraphs,
    TaskTypeCodes.fillInTheBlanksDragAndDrop =>
      ReadingStrings.readingHeaderTitleFillBlanksDragDrop,
    TaskTypeCodes.fillInTheBlanksDropdown =>
      ReadingStrings.readingHeaderTitleFillBlanksDropdown,
    _ => '',
  };
}

/// Maps a reading `TaskView.taskType` to the short English how-to-answer
/// instruction shown under its `ExamTaskHeaderBanner` title — same wording
/// pattern as the real PTE exam's per-task instructions, so a first-time
/// test-taker isn't left guessing the interaction. Unknown/non-reading
/// types return an empty string, same convention as [readingTaskHeaderTitle].
///
/// Still sourced from the not-yet-migrated `AppStrings` (see that file's
/// header comment) rather than [ReadingStrings] — move it over once the
/// rest of that migration lands.
String readingTaskInstruction(String taskType) {
  return switch (TaskTypeCodes.canonicalize(taskType)) {
    'MC_READING_SINGLE' => AppStrings.readingInstructionMcSingle,
    'MC_READING_MULTIPLE' => AppStrings.readingInstructionMcMultiple,
    'RE_ORDER_PARAGRAPHS' => AppStrings.readingInstructionReorderParagraphs,
    TaskTypeCodes.fillInTheBlanksDragAndDrop =>
      AppStrings.readingInstructionFillBlanksDragDrop,
    TaskTypeCodes.fillInTheBlanksDropdown =>
      AppStrings.readingInstructionFillBlanksDropdown,
    _ => '',
  };
}
