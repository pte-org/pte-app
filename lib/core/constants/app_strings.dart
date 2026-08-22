/// User-facing strings. No `Text('literal')` anywhere in the app — every
/// label goes through this class per `docs/CODING_STANDARDS_APP.md`.
class AppStrings {
  const AppStrings._();

  static const String appTitle = 'PTE Student';

  static const String sessionEntryTitle = 'Enter session ID';
  static const String sessionEntryFieldLabel = 'Session ID';
  static const String sessionEntryStartButton = 'Start';

  static const String examTaskCounterOf = ' / ';
  static const String examBrandLine1 = 'PTE UNI';
  static const String examBrandLine2 = 'Test of English Academic';
  static const String examBrandLine3 = 'TESTING ACCOUNT';
  static const String examTimeRemainingLabel = 'Time Remaining ';

  static const String taskAdvanceButtonLabel = 'Next';
  static const String writeEssayTextFieldLabel = 'Your response';
  static const String wordCountSuffix = ' words';
  static const String wordCountBoundsOpen = ' (';
  static const String wordCountMinLabel = 'min ';
  static const String wordCountMaxLabel = 'max ';
  static const String wordCountBoundsSeparator = ', ';
  static const String wordCountBoundsClose = ')';
  static const String unsupportedTaskTypePrefix = 'Unsupported task type: ';

  static const String readAloudInstructionPrefix = 'Look at the text below. In ';
  static const String readAloudInstructionMiddle =
      ' seconds, you must read this text aloud as naturally and clearly as possible. You have ';
  static const String readAloudInstructionSuffix = ' seconds to read aloud.';
  static const String readAloudAnswerCardTitle = 'Recorded Answer';

  // Shared by every auto-record speaking task's status card (Read Aloud,
  // Repeat Sentence) — not Read-Aloud-specific despite historically living
  // alongside those strings.
  static const String recordingCurrentStatusLabel = 'Current Status:';
  static const String recordingBeginningInPrefix = 'Beginning in ';
  static const String recordingBeginningInSuffix = ' seconds';
  static const String recordingInProgressPrefix = 'Recording ';
  static const String recordingInProgressSuffix = ' seconds left';
  static const String recordingStillUploadingLabel = 'Still uploading…';
  static const String recordingUploadReadyLabel = 'Uploaded — ready to continue.';

  static const String repeatSentenceInstructionText =
      'You will hear a sentence. Please repeat the sentence exactly as you hear it. You will hear the sentence '
      'only once.';
  static const String audioListeningVolumeLabel = 'Volume';
  static const String audioListeningPlayingPrefix = 'Playing ';
  static const String audioListeningPlayingSuffix = ' seconds left';

  static const String reportScreenTitle = 'Your report';
  static const String reportNotPublishedTitle = 'Waiting for your report';
  static const String reportNotPublishedMessage =
      'Your host hasn\'t published this report yet. Pull down to check again.';
  static const String reportErrorTitle = 'Something went wrong';
  static const String reportErrorMessage = 'We couldn\'t load your report. Pull down to try again.';
  static const String reportOverallSectionTitle = 'Overall';
  static const String reportCommunicativeSkillsSectionTitle = 'Communicative skills';
  static const String reportEnablingSkillsSectionTitle = 'Enabling skills';
  static const String reportInsufficientDataLabel = 'Insufficient data';

  static const String readingHeaderTitleMcSingle = 'Reading: Multiple Choice, Single Answer';
  static const String readingHeaderTitleMcMultiple = 'Reading: Multiple Choice, Multiple Answers';
  static const String readingHeaderTitleReorderParagraphs = 'Reading: Re-order Paragraphs';
  static const String readingHeaderTitleFillBlanksDragDrop = 'Reading: Fill in the Blanks';
  static const String readingHeaderTitleFillBlanksDropdown = 'Reading & Writing: Fill in the Blanks';
  static const String fillBlanksWordBankSectionLabel = 'Word bank';
  static const String fillBlanksGapPlaceholder = '_____';
  static const String reorderParagraphsHintLabel = 'Drag to reorder';
  static const String fillBlanksContentUnavailableTitle = 'Content being updated';
  static const String fillBlanksContentUnavailableMessage =
      'This task isn\'t ready to display yet. Please check back later.';

  static const String devTaskPreviewTitle = 'Task preview';
  static const String devReadingPreviewBlankGroupsUnavailableLabel =
      'FILL_BLANKS_READING_WRITING (blankGroups unavailable)';
  static const String devPreviewErrorPrefix = 'Dev preview error: ';
  static const String devPreviewTaskCompleteLabel = 'Task complete (dev preview).';
  static const String devPreviewPickAnotherLabel = 'Pick another';
}
