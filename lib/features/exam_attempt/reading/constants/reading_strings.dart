/// User-facing strings for the Reading skill's task-type screens.
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class ReadingStrings {
  const ReadingStrings._();

  static const String readingHeaderTitleMcSingle ='Reading: Multiple Choice, Single Answer';
  static const String readingHeaderTitleMcMultiple ='Reading: Multiple Choice, Multiple Answers';
  static const String readingHeaderTitleReorderParagraphs ='Reading: Re-order Paragraphs';
  static const String readingHeaderTitleFillBlanksDragDrop ='Reading: Fill in the Blanks';
  static const String readingHeaderTitleFillBlanksDropdown ='Reading & Writing: Fill in the Blanks';
  static const String fillBlanksWordBankSectionLabel ='Word bank';
  static const String fillBlanksGapPlaceholder ='_____';
  static const String reorderParagraphsHintLabel ='Drag to reorder';
  static const String fillBlanksContentUnavailableTitle ='Content being updated';
  static const String fillBlanksContentUnavailableMessage ='This task isn\'t ready to display yet. Please check back later.';
  static const String devReadingPreviewTitle ='Reading task preview';
  static const String devReadingPreviewBlankGroupsUnavailableLabel ='FILL_IN_THE_BLANKS_DROPDOWN (blankGroups unavailable)';
}
