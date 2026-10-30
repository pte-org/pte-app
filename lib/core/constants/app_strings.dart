/// User-facing strings. No `Text('literal')` anywhere in the app — every
/// label goes through this class per `docs/CODING_STANDARDS_APP.md`.
///
/// Note: `origin/dev` is mid-refactor — feature strings are being moved into
/// per-feature `constants/` classes (`ExamAttemptStrings`, `ReadingStrings`,
/// `SpeakingWritingStrings`, etc.). This file currently still holds the full
/// pre-refactor set because the move is incomplete; we keep it to avoid
/// breaking compilation for files that still reference `AppStrings.*`.
class AppStrings {
  const AppStrings._();

  static const String appTitle = 'PTE Student';

  static const String loginBrand = 'Pearson';
  static const String loginProduct = 'PTE Academic';
  static const String loginTitle = 'Candidate Sign-In';
  static const String loginUsernameLabel = 'Login username';
  static const String loginPasswordLabel = 'Login password';
  static const String loginSessionIdLabel = 'Exam code (optional)';
  static const String loginSessionIdRequiredLabel = 'Exam code';
  static const String loginSessionIdHint =
      'Enter the exam code provided by your exam host. Students must provide '
      'one before they can open an exam.';
  static const String loginSessionIdRequiredHint =
      'Enter the exam code provided by your exam host to continue.';
  static const String loginSessionIdRequired =
      'Exam code is required for student sign-in';
  static const String loginSubmit = 'Log in';
  static const String loginEmailLabel = loginUsernameLabel;
  static const String loginEmailRequired = 'Login username is required';
  static const String loginPasswordRequired = 'Login password is required';
  static const String loginFailure =
      'Sign-in failed. Check your credentials and try again.';
  static const String loginHeaderSystem = 'Test Delivery System';
  static const String loginFooterEnvironment =
      'Secure Test Environment - Workstation #08';
  static const String loginFooterCopyright =
      'Pearson VUE © All rights reserved';
  static const String loginHelp =
      'Your username and password are on the sheet provided by the Test '
      'Administrator. If you need assistance, please raise your hand.';

  static const String logout = 'Log out';
  static const String examAccessDeniedTitle = 'This app is for exam candidates';
  static const String examAccessDeniedMessage =
      'Your account is not a student account. Hosts, proctors and examiners '
      'work in the PTE web portal. Log out and sign in with a student account '
      'to take an exam.';

  static const String examPhasePrepLabel = 'Preparation';
  static const String examPhaseResponseLabel = 'Response';
  static const String examTaskCounterOf = ' / ';

  static const String taskAdvanceButtonLabel = 'Next';
  static const String taskAdvanceUnansweredNote =
      'Leaving this blank and clicking Next will be scored as incorrect.';
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
  static const String readAloudNotRecordedYetLabel =
      'Tap "Start recording" to begin.';
  static const String readAloudStillUploadingLabel = 'Still uploading…';
  static const String readAloudUploadReadyLabel =
      'Uploaded — ready to continue.';

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
  static const String reportErrorMessage =
      'We couldn\'t load your report. Pull down to try again.';
  static const String reportOverallSectionTitle = 'Overall';
  static const String reportCommunicativeSkillsSectionTitle =
      'Communicative skills';
  static const String reportInsufficientDataLabel = 'Insufficient data';

  static const String readingHeaderTitleMcSingle =
      'Reading: Multiple Choice, Single Answer';
  static const String readingHeaderTitleMcMultiple =
      'Reading: Multiple Choice, Multiple Answers';
  static const String readingHeaderTitleReorderParagraphs =
      'Reading: Re-order Paragraphs';
  static const String readingHeaderTitleFillBlanksDragDrop =
      'Reading: Fill in the Blanks';
  static const String readingHeaderTitleFillBlanksDropdown =
      'Reading & Writing: Fill in the Blanks';

  static const String readingInstructionMcSingle =
      'Read the text and answer the question by selecting the one correct response.';
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
  static const String fillBlanksContentUnavailableTitle =
      'Content being updated';
  static const String fillBlanksContentUnavailableMessage =
      'This task isn\'t ready to display yet. Please check back later.';

  static const String devReadingPreviewTitle = 'Reading task preview';
  static const String devReadingPreviewBlankGroupsUnavailableLabel =
      'FILL_IN_THE_BLANKS_DROPDOWN (blankGroups unavailable)';

  static const String readingInstructionsTitle = 'Reading';
  static const String readingInstructionsBody =
      'You will have approximately 29-30 minutes to complete 13-18 reading '
      'items. The countdown timer applies to the whole Reading section, not '
      'to each individual question — once it starts, you cannot go back to '
      'a previous question after moving on.';
  static const String readingInstructionsButtonLabel = 'Next';

  /// Last-resort instruction when neither the API nor TaskTypeMeta has one.
  static const String defaultTaskInstruction =
      'Follow the instructions for this task.';

  static const String sectionCompletedTimeUpTitle = 'Time is up';
  static const String sectionCompletedTimeUpMessage =
      'The time allowed for this exam has ended. Your answers so far have been saved.';
  static const String sectionCompletedNaturalTitle = 'Exam completed';
  static const String sectionCompletedNaturalMessage =
      'You have completed every question in this exam.';
  static const String examAttemptNumberLabel = 'Attempt';
  static const String examRetriesRemainingMessage = 'Retries remaining';
  static const String examRetryButton = 'Try again';
  static const String sectionCompletedContinueButton = 'Continue';

  // Writing task — text-editor toolbar tooltips.
  static const String editorCutTooltip = 'Cut';
  static const String editorCopyTooltip = 'Copy';
  static const String editorPasteTooltip = 'Paste';
  static const String editorUndoTooltip = 'Undo';
  static const String editorRedoTooltip = 'Redo';

  // Writing task — Summarize Written Text.
  static const String summarizeWrittenTextTitle = 'Summarize Written Text';
  static const String summarizeWrittenTextInstruction =
      'Read the passage below and summarize it in one sentence (5 to 75 words).'
      ' You will have 10 minutes to complete this task.';
  static const String summarizeWrittenTextResponseLabel =
      'Your response (one sentence)';

  // Writing task — Write Essay (used when rendering without BLoC integration).
  static const String writeEssayV2Title = 'Write Essay';
  static const String writeEssayV2Instruction =
      'You will have 20 minutes to plan, write and revise an essay about the topic below.'
      ' Your response will be judged on how well you develop a position, organize ideas,'
      ' and use language appropriately. Write 200-300 words.';
  static const String writeEssayV2ResponseLabel = 'Your essay';

  // Writing task — shared labels.
  static const String countdownLabelPrefix = 'Time Remaining ';
  static const String passagePanelLabel = 'Reading passage';
}
