/// User-facing strings for the Speaking/Writing skills' task-type screens.
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class SpeakingWritingStrings {
  const SpeakingWritingStrings._();

// Shared chrome labels for read-aloud / write-essay v1 (from HEAD).
  static const String writeEssayTextFieldLabel = 'Your response';
  static const String readAloudStartRecordingLabel = 'Start recording';
  static const String readAloudStopRecordingLabel = 'Stop recording';
  static const String readAloudRecordingIndicator = 'Recording…';
  static const String readAloudNotRecordedYetLabel = 'Tap "Start recording" to begin.';
  static const String readAloudStillUploadingLabel = 'Still uploading…';
  static const String readAloudUploadReadyLabel = 'Uploaded — ready to continue.';

  // Dev preview title (from origin/dev).
  static const String devSpeakingWritingPreviewTitle =
      'Speaking/Writing task preview';

  // Read-aloud templated instruction (from origin/dev).
  static const String readAloudInstructionPrefix =
      'Look at the text below. In ';
  static const String readAloudInstructionMiddle =
      ' seconds, you must read this text aloud as naturally and clearly as possible. You have ';
  static const String readAloudInstructionSuffix = ' seconds to read aloud.';
  static const String recordedAnswerCardTitle = 'Recorded Answer';

  // Shared by every auto-record speaking task's status card (Read Aloud,
  // Repeat Sentence, Describe Image) — not Read-Aloud-specific despite
  // historically living alongside those strings (from origin/dev).
  static const String recordingCurrentStatusLabel = 'Current Status:';
  static const String recordingBeginningInPrefix = 'Beginning in ';
  static const String recordingBeginningInSuffix = ' seconds';
  static const String recordingInProgressPrefix = 'Recording ';
  static const String recordingInProgressSuffix = ' seconds left';
  static const String recordingStillUploadingLabel = 'Still uploading…';
  static const String recordingUploadReadyLabel =
      'Uploaded — ready to continue.';

  // Describe-image instruction + image fallback labels (from origin/dev).
  static const String describeImageInstructionPrefix =
      'Look at the image below. In ';
  static const String describeImageInstructionMiddle =
      ' seconds, please speak into the microphone and describe in detail what the image is showing. You will have ';
  static const String describeImageInstructionSuffix =
      ' seconds to give your response.';
  static const String taskImageLoadErrorLabel = 'Image failed to load.';
  static const String taskImageMissingLabel =
      'No image available for this task.';

  // Repeat sentence + answer short question + group discussion + situation
  // instruction copy (from origin/dev).
  static const String repeatSentenceInstructionText =
      'You will hear a sentence. Please repeat the sentence exactly as you hear it. You will hear the sentence '
      'only once.';
  static const String answerShortQuestionInstructionText =
      'You will hear a question. Please give a simple and short answer. Often just once or a few words is '
      'enough.';
  static const String summarizeGroupDiscussionInstructionText =
      'You will hear a group discussion. Please summarize the discussion, including the key points and '
      'opinions expressed by each speaker.';
  static const String respondToASituationInstructionText =
      'Read the situation below. You will then hear it described again. Please respond appropriately, as you '
      'would in the actual situation.';

  // Listening audio meter copy (from origin/dev, lives here for proximity to
  // speaking status-card chrome).
  static const String audioListeningVolumeLabel = 'Volume';
  static const String audioListeningPlayingPrefix = 'Playing ';
  static const String audioListeningPlayingSuffix = ' seconds left';

  // AudioPromptCubit error-state copy (plans/phat-speaking-audio-prompt-e2e)
  // — shown in place of the progress bar when the on-demand `/audio` call
  // fails; never the raw exception text.
  static const String audioPromptReplayLimitExceededMessage =
      'No plays left for this audio.';
  static const String audioPromptUrlExpiredMessage =
      'This audio link expired — continue when the response window starts.';
  static const String audioPromptGenericErrorMessage =
      'Audio failed to load — continue when the response window starts.';

  // Retell lecture instruction (from origin/dev).
  static const String retellLectureInstructionPrefix =
      'You will hear a lecture. After listening to the lecture, in ';
  static const String retellLectureInstructionMiddle =
      ' seconds, please speak into the microphone and retell what you just heard from the lecture in your own '
      'words. You will have ';
  static const String retellLectureInstructionSuffix =
      ' seconds to give your response.';

  // Personal introduction instruction (from origin/dev).
  static const String personalIntroductionInstructionPrefix =
      'Read the prompt below. In ';
  static const String personalIntroductionInstructionMiddle =
      ' seconds, you must reply in your own words, as naturally and clearly as possible. You have ';
  static const String personalIntroductionInstructionSuffix =
      ' seconds to record your response.';
}
