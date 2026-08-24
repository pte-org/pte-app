/// User-facing strings. No `Text('literal')` anywhere in the app — every
/// label goes through this class per `docs/CODING_STANDARDS_APP.md`.
class AppStrings {
  const AppStrings._();

  static const String appTitle = 'PTE Student';

  static const String loginTitle = 'Log in';
  static const String loginEmailFieldLabel = 'Email';
  static const String loginPasswordFieldLabel = 'Password';
  static const String loginButtonLabel = 'Log in';
  static const String logoutButtonLabel = 'Log out';

  static const String sessionEntryTitle = 'Enter session ID';
  static const String sessionEntryFieldLabel = 'Session ID';
  static const String sessionEntryStartButton = 'Start';

  static const String examPhasePrepLabel = 'Preparation';
  static const String examPhaseResponseLabel = 'Response';
  static const String examTaskCounterOf = ' / ';

  static const String taskAdvanceButtonLabel = 'Next';
  static const String taskAdvanceUnansweredNote = 'Leaving this blank and clicking Next will be scored as incorrect.';
  static const String writeEssayTextFieldLabel = 'Your response';
  static const String wordCountSuffix = ' words';
  static const String wordCountBoundsOpen = ' (';
  static const String wordCountMinLabel = 'min ';
  static const String wordCountMaxLabel = 'max ';
  static const String wordCountBoundsSeparator = ', ';
  static const String wordCountBoundsClose = ')';
  static const String unsupportedTaskTypePrefix = 'Unsupported task type: ';

  static const String readAloudStartRecordingLabel = 'Start recording';
  static const String readAloudStopRecordingLabel = 'Stop recording';
  static const String readAloudRecordingIndicator = 'Recording…';
  static const String readAloudNotRecordedYetLabel = 'Tap "Start recording" to begin.';
  static const String readAloudStillUploadingLabel = 'Still uploading…';
  static const String readAloudUploadReadyLabel = 'Uploaded — ready to continue.';

  static const String forceSubmitButtonLabel = 'Submit exam';
  static const String forceSubmitDialogTitle = 'Submit exam now?';
  static const String forceSubmitDialogMessage =
      'This ends your attempt immediately, including any tasks not yet answered. This cannot be undone.';
  static const String forceSubmitDialogConfirm = 'Submit';
  static const String forceSubmitDialogCancel = 'Cancel';

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

  static const String readingInstructionMcSingle = 'Read the text and answer the question by selecting the one correct response.';
  static const String readingInstructionMcMultiple =
      'Read the text and answer the question by selecting all the correct responses. More than one response may be correct.';
  static const String readingInstructionReorderParagraphs =
      'The paragraphs below are not in the correct order. Drag and drop them up or down to restore the original, logical order.';
  static const String readingInstructionFillBlanksDragDrop =
      'Some words are missing from the text below. Drag words from the box below to the appropriate blank. Drag a word back to the box to undo it.';
  static const String readingInstructionFillBlanksDropdown =
      'Click on each blank in the text below. A list of choices will appear — select the word that best completes the text.';
  static const String fillBlanksWordBankSectionLabel = 'Word bank';
  static const String fillBlanksGapPlaceholder = '_____';
  static const String reorderParagraphsHintLabel = 'Drag to reorder';
  static const String fillBlanksContentUnavailableTitle = 'Content being updated';
  static const String fillBlanksContentUnavailableMessage =
      'This task isn\'t ready to display yet. Please check back later.';

  static const String devReadingPreviewTitle = 'Reading task preview';
  static const String devReadingPreviewBlankGroupsUnavailableLabel =
      'FILL_BLANKS_READING_WRITING (blankGroups unavailable)';

  static const String readingInstructionsTitle = 'Reading';
  static const String readingInstructionsBody =
      'You will have approximately 29-30 minutes to complete 13-18 reading '
      'items. The countdown timer applies to the whole Reading section, not '
      'to each individual question — once it starts, you cannot go back to '
      'a previous question after moving on.';
  static const String readingInstructionsButtonLabel = 'Next';

  static const String sectionCompletedTimeUpTitle = 'Time is up';
  static const String sectionCompletedTimeUpMessage =
      'The time allowed for this section has ended. Your answers so far have been saved.';
  static const String sectionCompletedNaturalTitle = 'Reading Section Completed';
  static const String sectionCompletedNaturalMessage = 'You have answered every question in this section.';
  static const String sectionCompletedContinueButton = 'Continue';
}
