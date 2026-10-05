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
  static const String retryLimitReachedCode = 'RETRY_LIMIT_REACHED';
  static const String retryLimitReachedMessage =
      'You have used all attempts for this exam. Please contact your host if you need help.';
  static const String attemptStartRetry = 'Try again';
  static const String attemptStartChangeSession = 'Use a different exam code';
  static const String sessionResolutionFailureMessage =
      "We couldn't find that exam code. Check the code from your host and try again.";
  static const String lockdownStartFailureMessage =
      'Some required security checks could not be completed. Review the details and retry after fixing them.';
  static const String forceSubmitButtonLabel = 'Finish exam';
  static const String forceSubmitRetryLabel = 'Retry submit';
  static const String forceSubmitSubmittingLabel = 'Submitting…';
  static const String forceSubmitDialogTitle = 'Submit exam now?';
  static String forceSubmitDialogMessage({
    required int answeredTasks,
    required int unansweredTasks,
  }) =>
      'You have answered $answeredTasks task${answeredTasks == 1 ? '' : 's'} '
      'and left $unansweredTasks task${unansweredTasks == 1 ? '' : 's'} '
      'unanswered. Unanswered tasks will be submitted blank. '
      'This ends your attempt immediately and cannot be undone.';
  static const String forceSubmitDialogConfirm = 'Submit';
  static const String forceSubmitDialogCancel = 'Cancel';
  static const String forceSubmitInProgress =
      'Submitting your exam. Keep this window open until submission is confirmed.';
  static const String forceSubmitRetryMessage =
      'The server did not confirm submission. Your exam is still open; retry when ready.';
  static const String forceSubmitAnswersPendingMessage =
      'Some answers are still being saved. Keep the exam open and retry submit.';
  static const String forceSubmitMediaPendingMessage =
      'A recorded response is still uploading. Keep the exam open and retry submit.';

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
