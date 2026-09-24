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
  static const String loginSessionIdLabel = 'Exam session ID (optional)';
  static const String loginSessionIdRequiredLabel = 'Exam session ID';
  static const String loginSessionIdHint =
      'Enter the session ID provided by your exam host. Students must provide '
      'one before they can open an exam.';
  static const String loginSessionIdRequiredHint =
      'Enter the session ID provided by your exam host to continue.';
  static const String loginSessionIdRequired =
      'Exam session ID is required for student sign-in';
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

  static const String hostConsoleTitle = 'Host Console';
  static const String hostConsoleWelcome = 'Welcome to the Host workspace.';
  static const String logout = 'Log out';
  static const String studentWorkspacePlaceholder = 'PTE Student';

  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  // `edit`/`delete` are otherwise unused (their one caller, the old
  // question-authoring module, was deleted in Plan B Phase 8) but stay
  // defined: host_audit's own widget tests assert these labels are absent
  // from its pages.
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String sessionsTitle = 'Exam sessions';
  static const String sessionsEmpty = 'No exam sessions yet.';
  static const String sessionsLoadFailure = 'Sessions could not be loaded.';
  static const String createSession = 'Create session';
  static const String createSessionTitle = 'Schedule exam session';
  static const String sessionNameLabel = 'Session name';
  static const String examSkillsLabel = 'Skills';
  static const String examSkillsHint =
      'The system randomly generates the exam from the question bank for the skills you pick (1 to 4).';
  static const String examSkillSpeaking = 'Speaking';
  static const String examSkillWriting = 'Writing';
  static const String examSkillReading = 'Reading';
  static const String examSkillListening = 'Listening';
  static const String opensAtLabel = 'Opens at (ISO-8601)';
  static const String closesAtLabel = 'Closes at (ISO-8601)';
  static const String sessionWindowHint = 'Example: 2026-07-29T08:00:00Z';
  static const String sessionValidationFailure =
      'Enter a name, select 1 to 4 skills, and a valid future session window.';
  static const String sessionCreateFailure =
      'Session could not be created. Try again.';
  static const String sessionDetailTitle = 'Session detail';
  static const String sessionStatusLabel = 'Status';
  static const String sessionSnapshotLabel = 'Snapshot';
  static const String sessionWindowLabel = 'Availability';
  static const String assignedClassesTitle = 'Assigned Classes';
  static const String assignedClassesEmpty = 'No Classes assigned yet.';
  static const String classAssignmentLocked =
      'Classes can only be assigned or unassigned while this exam is Scheduled.';
  static const String classPublicIdLabel = 'Class public ID';
  static const String assignClass = 'Assign Class';
  static const String openSession = 'Open session';
  static const String closeSession = 'Close session';
  static const String sessionTransitionConfirmation = 'Confirm session action?';
  static const String sessionConflict =
      'Session changed on the server. The latest state has been reloaded.';
  static const String sessionMutationFailure =
      'The session could not be updated. Try again.';
  static const String manageParticipants = 'Manage participants';
  static const String participantManagementTitle = 'Enrollment and proctor';
  static const String studentsTitle = 'Eligible students';
  static const String proctorsTitle = 'Eligible proctors';
  static const String enrollStudent = 'Enroll student';
  static const String assignProctor = 'Assign proctor';
  static const String usersLoadFailure = 'Eligible users could not be loaded.';
  static const String noEligibleUsers = 'No eligible users found.';
  static const String participantCommandSuccess = 'Command completed.';
  static const String participantCommandFailure =
      'Command failed. Your selection was preserved.';
  static const String participantConfirmation = 'Confirm participant action?';
  static const String confirm = 'Confirm';
  static const String scoringReviewTitle = 'Scoring and review';
  static const String requestScoring = 'Request scoring';
  static const String publishResults = 'Publish results';
  static const String pendingReviewsTitle = 'Pending essay reviews';
  static const String pendingReviewsEmpty = 'No essays are waiting for review.';
  static const String scoringReviewsLoadFailure =
      'Pending reviews could not be loaded.';
  static const String scoringCommandFailure =
      'The scoring command could not be completed.';
  static const String scoringConflict =
      'The backend gate rejected this action. Refresh and check pending reviews.';
  static const String scoringCommandSuccess = 'Command accepted.';
  static const String approveReview = 'Approve review';
  static const String reviewConfirmation = 'Approve this scored essay?';
  static const String attemptLabel = 'Attempt';
  static const String taskTypeLabel = 'Task type';
  static const String rawScoreLabel = 'Raw score';
  static const String loadMore = 'Load more';
  static const String notificationAuditTitle = 'Notification delivery audit';
  static const String notificationAuditEmpty = 'No notification records yet.';
  static const String notificationAuditFailure =
      'Notification records could not be loaded.';
  static const String violationAuditTitle = 'Session violation audit';
  static const String violationAuditEmpty = 'No violations recorded.';
  static const String violationAuditFailure =
      'Violation records could not be loaded.';
  static const String publicIdLabel = 'Public ID';
  static const String recipientLabel = 'Recipient';
  static const String notificationTypeLabel = 'Notification type';
  static const String subjectLabel = 'Subject';
  static const String deliveryStatusLabel = 'Delivery status';
  static const String sentAtLabel = 'Sent at';
  static const String notSent = 'Not sent';
  static const String violationTypeLabel = 'Violation type';
  static const String violationDetailLabel = 'Detail';
  static const String sequenceLabel = 'Sequence';
  static const String integrityHashLabel = 'Integrity hash';
  static const String detectedAtLabel = 'Detected at';
  static const String proctorWorkspaceTitle = 'Assigned exam sessions';
  static const String assignedSessionsEmpty = 'No sessions assigned to you.';
  static const String liveMonitoringTitle = 'Live monitoring';
  static const String liveReadOnlyNotice =
      'Read-only monitoring. Proctor commands are disabled.';
  static const String liveConnectionLabel = 'Connection';
  static const String liveReconnect = 'Reconnect';
  static const String liveAttemptIdLabel = 'Attempt public ID';
  static const String liveForceSubmit = 'Force submit';
  static const String liveFlagViolation = 'Flag violation';
  static const String liveViolationsTitle = 'Live violations';
  static const String liveCommandConfirmation = 'Confirm proctor command?';
  static const String liveViolationConfirmation = 'Confirm violation flag?';

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
  static const String sectionCompletedNaturalTitle =
      'Reading Section Completed';
  static const String sectionCompletedNaturalMessage =
      'You have answered every question in this section.';
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
