/// User-facing strings shared across every listening/reading/speaking/writing
/// task-type screen (exam shell chrome, word-count labels, force-submit).
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class ExamAttemptStrings {
  const ExamAttemptStrings._();

  static const String sessionEntryTitle ='Enter session ID';
  static const String sessionEntryFieldLabel ='Session ID';
  static const String sessionEntryStartButton ='Start';
  static const String examPhasePrepLabel ='Preparation';
  static const String examPhaseResponseLabel ='Response';
  static const String examTaskCounterOf =' / ';
  static const String taskAdvanceButtonLabel ='Next';
  static const String wordCountSuffix =' words';
  static const String wordCountBoundsOpen =' (';
  static const String wordCountMinLabel ='min ';
  static const String wordCountMaxLabel ='max ';
  static const String wordCountBoundsSeparator =', ';
  static const String wordCountBoundsClose =')';
  static const String unsupportedTaskTypePrefix ='Unsupported task type: ';
  static const String forceSubmitButtonLabel ='Submit exam';
  static const String forceSubmitDialogTitle ='Submit exam now?';
  static const String forceSubmitDialogMessage ='This ends your attempt immediately, including any tasks not yet answered. This cannot be undone.';
  static const String forceSubmitDialogConfirm ='Submit';
  static const String forceSubmitDialogCancel ='Cancel';

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
