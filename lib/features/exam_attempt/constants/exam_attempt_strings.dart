/// User-facing strings shared across every listening/reading/speaking/writing
/// task-type screen (exam shell chrome, word-count labels, force-submit).
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class ExamAttemptStrings {
  const ExamAttemptStrings._();

  static const String examPhasePrepLabel = 'Preparation';
  static const String examPhaseResponseLabel = 'Response';
  static const String examTaskCounterOf = ' / ';
  static const String taskAdvanceButtonLabel = 'Next';
  static const String wordCountSuffix = ' words';
  static const String wordCountBoundsOpen = ' (';
  static const String wordCountMinLabel = 'min ';
  static const String wordCountMaxLabel = 'max ';
  static const String wordCountBoundsSeparator = ', ';
  static const String wordCountBoundsClose = ')';
  static const String unsupportedTaskTitle = 'This exam needs an app update';
  static const String unsupportedTaskMessage =
      'This task is not supported by the current app version, so the exam is paused to protect your result.';
  static const String unsupportedTaskContactHost =
      'Please update the app or contact your exam host for help.';
  static const String examRequiresAppUpdateCode = 'EXAM_REQUIRES_APP_UPDATE';
  static const String examConfigurationNotCompatibleCode =
      'EXAM_CONFIGURATION_NOT_COMPATIBLE';
  static const String examRequiresAppUpdateMessage =
      'This exam needs a newer app version. Please update the app and try again, or contact your exam host for help.';
  static const String examConfigurationNotCompatibleMessage =
      'This exam is not ready to run on the current configuration. Please contact your exam host for assistance.';
  static const String attemptStartFailureTitle = 'Unable to start exam';
  static const String attemptContinueFailureTitle = 'Unable to continue exam';
  static const String attemptStartRetry = 'Try again';
  static const String attemptStartChangeSession = 'Use a different session';
  static const String sessionResolutionFailureMessage =
      'We could not open this exam session. Check the session ID from your host and try again.';
  static const String lockdownStartFailureMessage =
      'Some required security checks could not be completed. Review the details and retry after fixing them.';
  static const String forceSubmitButtonLabel = 'Submit exam';
  static const String forceSubmitDialogTitle = 'Submit exam now?';
  static const String forceSubmitDialogMessage =
      'This ends your attempt immediately, including any tasks not yet answered. This cannot be undone.';
  static const String forceSubmitDialogConfirm = 'Submit';
  static const String forceSubmitDialogCancel = 'Cancel';

  // Lockdown activation failure dialog (Phase 5).
  static const String lockdownFailureTitle = 'Cannot start exam';
  static const String lockdownFailureMessage =
      'The following security checks failed:';
  static const String lockdownFailureRetry = 'Retry';
  static const String lockdownFailureCancel = 'Cancel';

  // Lockdown violation warning banner (Phase 5). Generic per-type
  // copy — the proctor-facing copy is computed by
  // `ViolationWarningBanner` from the violation type key.
  static const String violationFullscreenExit =
      'Exiting fullscreen is not allowed during an exam.';
  static const String violationClipboardPaste =
      'Pasting from external sources is not allowed during an exam.';
  static const String violationShortcutBlocked =
      'System shortcuts are disabled during an exam.';
  static const String violationForbiddenApp =
      'A forbidden application was detected. Please close it.';
  static const String violationGeneric =
      'A security policy violation was detected.';
}
