/// User-facing strings. No `Text('literal')` anywhere in the app — every
/// label goes through this class per `docs/CODING_STANDARDS_APP.md`.
class AppStrings {
  const AppStrings._();

  static const String appTitle = 'PTE Student';

  static const String loginTitle = 'Sign in';
  static const String loginEmailLabel = 'Email';
  static const String loginPasswordLabel = 'Password';
  static const String loginSubmit = 'Sign in';
  static const String loginEmailRequired = 'Email is required';
  static const String loginPasswordRequired = 'Password is required';
  static const String loginFailure =
      'Sign-in failed. Check your credentials and try again.';

  static const String hostConsoleTitle = 'Host Console';
  static const String hostConsoleWelcome = 'Welcome to the Host workspace.';
  static const String logout = 'Log out';
  static const String studentWorkspacePlaceholder = 'PTE Student';

  static const String questionsTitle = 'Question bank';
  static const String questionsEmpty = 'No accessible questions yet.';
  static const String questionsLoadFailure = 'Questions could not be loaded.';
  static const String retry = 'Retry';
  static const String createQuestion = 'Create question';
  static const String createQuestionTitle = 'Create MC Reading Single';
  static const String questionTitleLabel = 'Question title';
  static const String questionPromptLabel = 'Prompt';
  static const String questionOptionLabel = 'Option';
  static const String correctOptionLabel = 'Correct answer';
  static const String addOption = 'Add option';
  static const String removeOption = 'Remove option';
  static const String createQuestionSubmit = 'Create';
  static const String authoringFieldRequired = 'This field is required';
  static const String authoringValidationFailure =
      'Enter a title, prompt, at least two options, and select exactly one correct answer.';
  static const String createQuestionFailure =
      'Question could not be created. Try again.';
  static const String selectQuestionType = 'Select question type';
  static const String mcReadingSingleLabel = 'MC Reading Single';
  static const String readAloudLabel = 'Read Aloud';
  static const String writeEssayLabel = 'Write Essay';
  static const String createReadAloudTitle = 'Create Read Aloud';
  static const String createWriteEssayTitle = 'Create Write Essay';
  static const String referenceAnswerLabel = 'Reference answer';
  static const String minWordCountLabel = 'Minimum word count';
  static const String maxWordCountLabel = 'Maximum word count';
  static const String wordCountInvalid =
      'Use positive word counts with minimum not greater than maximum';
  static const String blueprintsTitle = 'Exam blueprints';
  static const String blueprintsEmpty = 'No blueprints yet.';
  static const String blueprintsLoadFailure = 'Blueprints could not be loaded.';
  static const String createBlueprint = 'Create blueprint';
  static const String blueprintNameLabel = 'Blueprint name';
  static const String blueprintQuestionsLabel = 'Select questions in order';
  static const String blueprintValidationFailure =
      'Enter a name and select at least one question.';
  static const String blueprintCreateFailure =
      'Blueprint could not be created. Try again.';
  static const String blueprintDetailTitle = 'Blueprint detail';
  static const String publishBlueprint = 'Publish snapshot';
  static const String publishConfirmationTitle = 'Publish immutable snapshot?';
  static const String publishConfirmationBody =
      'The snapshot is read-only. Create a new blueprint for later changes.';
  static const String cancel = 'Cancel';
  static const String publish = 'Publish';
  static const String publishFailure = 'Snapshot could not be published.';
  static const String snapshotTitle = 'Immutable snapshot';
  static const String snapshotVersion = 'Version';
  static const String snapshotSource = 'Source blueprint';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String sessionsTitle = 'Exam sessions';
  static const String sessionsEmpty = 'No exam sessions yet.';
  static const String sessionsLoadFailure = 'Sessions could not be loaded.';
  static const String createSession = 'Create session';
  static const String createSessionTitle = 'Schedule exam session';
  static const String sessionNameLabel = 'Session name';
  static const String snapshotIdLabel = 'Published snapshot ID';
  static const String opensAtLabel = 'Opens at (ISO-8601)';
  static const String closesAtLabel = 'Closes at (ISO-8601)';
  static const String sessionWindowHint = 'Example: 2026-07-29T08:00:00Z';
  static const String sessionValidationFailure =
      'Enter a name, snapshot ID, and a valid future session window.';
  static const String sessionCreateFailure =
      'Session could not be created. Try again.';
  static const String sessionDetailTitle = 'Session detail';
  static const String sessionStatusLabel = 'Status';
  static const String sessionSnapshotLabel = 'Snapshot';
  static const String sessionWindowLabel = 'Availability';
  static const String compositionTitle = 'Task composition';
  static const String compositionHint =
      'Select all task types for a full mock, or a subset for practice.';
  static const String compositionEmpty = 'This snapshot has no task types.';
  static const String saveComposition = 'Save composition';
  static const String compositionValidationFailure =
      'Select at least one task type.';
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

  static const String sessionEntryTitle = 'Enter session ID';
  static const String sessionEntryFieldLabel = 'Session ID';
  static const String sessionEntryStartButton = 'Start';

  static const String examPhasePrepLabel = 'Preparation';
  static const String examPhaseResponseLabel = 'Response';
  static const String examTaskCounterOf = ' / ';

  static const String taskAdvanceButtonLabel = 'Next';
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
  static const String reportEnablingSkillsSectionTitle = 'Enabling skills';
  static const String reportInsufficientDataLabel = 'Insufficient data';
}
