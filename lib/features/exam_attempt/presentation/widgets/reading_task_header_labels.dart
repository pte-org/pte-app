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
