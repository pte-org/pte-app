/// User-facing strings for the Reading skill's task-type screens.
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class ReadingStrings {
  const ReadingStrings._();
  static const source = 'Source';
  static const target = 'Target';
  static const moveToTarget = 'Move to Target';
  static const moveToSource = 'Move to Source';
  static const moveUp = 'Move up';
  static const moveDown = 'Move down';
  static const dragDropInstruction =
      'In the text below some words are missing. Drag words from the box below '
      'to the appropriate place in the text. To undo an answer choice, drag '
      'the word back to the box below the text.';
  static String dragGapLabel(int index, String? word) => word == null
      ? 'Gap ${index + 1}, empty'
      : "Gap ${index + 1}, filled with '$word'";
  static String dragWordLabel(String word) => "Word chip '$word', draggable";
  static String inlineBlankLabel(int number) => 'Blank $number';
  static const String fillBlanksDropdownInstruction =
      'Select the best word for each blank.';

  static const String readingHeaderTitleMcSingle =
      'Multiple Choice, Single Answer';
  static const String readingHeaderTitleMcMultiple =
      'Reading: Multiple Choice, Multiple Answers';
  static const String readingHeaderTitleReorderParagraphs =
      'Reading: Re-order Paragraphs';
  static const String readingHeaderTitleFillBlanksDragDrop =
      'Reading: Fill in the Blanks';
  static const String readingHeaderTitleFillBlanksDropdown =
      'Reading & Writing: Fill in the Blanks';
  static const String fillBlanksWordBankSectionLabel = 'Word bank';
  static const String fillBlanksGapPlaceholder = '_____';
  static const String reorderParagraphsHintLabel = 'Drag to reorder';
  static const String fillBlanksContentUnavailableTitle =
      'Content being updated';
  static const String fillBlanksContentUnavailableMessage =
      'This task isn\'t ready to display yet. Please check back later.';
  static const String devReadingPreviewTitle = 'Reading task preview';
  static const String devReadingPreviewBlankGroupsUnavailableLabel =
      'FILL_IN_THE_BLANKS_DROPDOWN (blankGroups unavailable)';
}
