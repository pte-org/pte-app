import '../../../../core/constants/app_strings.dart';

/// Maps a reading `TaskView.taskType` to its [ReadingTaskHeaderBanner] title.
/// Unknown/non-reading types return an empty string — callers only invoke
/// this from the 5 reading task screens, which always pass a known type.
String readingTaskHeaderTitle(String taskType) {
  return switch (taskType) {
    'MC_READING_SINGLE' => AppStrings.readingHeaderTitleMcSingle,
    'MC_READING_MULTIPLE' => AppStrings.readingHeaderTitleMcMultiple,
    'RE_ORDER_PARAGRAPHS' => AppStrings.readingHeaderTitleReorderParagraphs,
    'FILL_BLANKS_READING' => AppStrings.readingHeaderTitleFillBlanksDragDrop,
    'FILL_BLANKS_READING_WRITING' => AppStrings.readingHeaderTitleFillBlanksDropdown,
    _ => '',
  };
}

/// Maps a reading `TaskView.taskType` to the short English how-to-answer
/// instruction shown under its [ReadingTaskHeaderBanner] title — same
/// wording pattern as the real PTE exam's per-task instructions, so a
/// first-time test-taker isn't left guessing the interaction. Unknown/
/// non-reading types return an empty string, same convention as
/// [readingTaskHeaderTitle].
String readingTaskInstruction(String taskType) {
  return switch (taskType) {
    'MC_READING_SINGLE' => AppStrings.readingInstructionMcSingle,
    'MC_READING_MULTIPLE' => AppStrings.readingInstructionMcMultiple,
    'RE_ORDER_PARAGRAPHS' => AppStrings.readingInstructionReorderParagraphs,
    'FILL_BLANKS_READING' => AppStrings.readingInstructionFillBlanksDragDrop,
    'FILL_BLANKS_READING_WRITING' => AppStrings.readingInstructionFillBlanksDropdown,
    _ => '',
  };
}
