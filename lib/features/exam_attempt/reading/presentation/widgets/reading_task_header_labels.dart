import 'package:pte_app/features/exam_attempt/reading/constants/reading_strings.dart';

/// Maps a reading `TaskView.taskType` to its [ReadingTaskHeaderBanner] title.
/// Unknown/non-reading types return an empty string — callers only invoke
/// this from the 5 reading task screens, which always pass a known type.
String readingTaskHeaderTitle(String taskType) {
  return switch (taskType) {
    'MC_READING_SINGLE' => ReadingStrings.readingHeaderTitleMcSingle,
    'MC_READING_MULTIPLE' => ReadingStrings.readingHeaderTitleMcMultiple,
    'RE_ORDER_PARAGRAPHS' => ReadingStrings.readingHeaderTitleReorderParagraphs,
    'FILL_BLANKS_READING' => ReadingStrings.readingHeaderTitleFillBlanksDragDrop,
    'FILL_BLANKS_READING_WRITING' => ReadingStrings.readingHeaderTitleFillBlanksDropdown,
    _ => '',
  };
}
