/// User-facing strings for the Speaking/Writing skills' task-type screens.
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class SpeakingWritingStrings {
  const SpeakingWritingStrings._();

  static const String devSpeakingWritingPreviewTitle =
      'Speaking/Writing task preview';

  static const String writeEssayTextFieldLabel = 'Your response';

  static const String readAloudInstructionPrefix =
      'Look at the text below. In ';
  static const String readAloudInstructionMiddle =
      ' seconds, you must read this text aloud as naturally and clearly as possible. You have ';
  static const String readAloudInstructionSuffix = ' seconds to read aloud.';
  static const String recordedAnswerCardTitle = 'Recorded Answer';

  // Shared by every auto-record speaking task's status card (Read Aloud,
  // Repeat Sentence, Describe Image) — not Read-Aloud-specific despite
  // historically living alongside those strings.
  static const String recordingCurrentStatusLabel = 'Current Status:';
  static const String recordingBeginningInPrefix = 'Beginning in ';
  static const String recordingBeginningInSuffix = ' seconds';
  static const String recordingInProgressPrefix = 'Recording ';
  static const String recordingInProgressSuffix = ' seconds left';
  static const String recordingStillUploadingLabel = 'Still uploading…';
  static const String recordingUploadReadyLabel =
      'Uploaded — ready to continue.';

  static const String describeImageInstructionPrefix =
      'Look at the image below. In ';
  static const String describeImageInstructionMiddle =
      ' seconds, please speak into the microphone and describe in detail what the image is showing. You will have ';
  static const String describeImageInstructionSuffix =
      ' seconds to give your response.';
  static const String taskImageLoadErrorLabel = 'Image failed to load.';
  static const String taskImageMissingLabel =
      'No image available for this task.';

  static const String repeatSentenceInstructionText =
      'You will hear a sentence. Please repeat the sentence exactly as you hear it. You will hear the sentence '
      'only once.';
  static const String audioListeningVolumeLabel = 'Volume';
  static const String audioListeningPlayingPrefix = 'Playing ';
  static const String audioListeningPlayingSuffix = ' seconds left';

  static const String retellLectureInstructionPrefix =
      'You will hear a lecture. After listening to the lecture, in ';
  static const String retellLectureInstructionMiddle =
      ' seconds, please speak into the microphone and retell what you just heard from the lecture in your own '
      'words. You will have ';
  static const String retellLectureInstructionSuffix =
      ' seconds to give your response.';
}
