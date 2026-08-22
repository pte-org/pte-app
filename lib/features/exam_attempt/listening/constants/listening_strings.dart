/// User-facing strings for the Listening skill's task-type screens.
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class ListeningStrings {
  const ListeningStrings._();

  static const String listeningAudioPlayingLabel ='Playing…';
  static const String listeningAudioFinishedLabel ='Audio finished';
  static const String devListeningPreviewTitle ='Listening task preview';
  static const String writeFromDictationPrompt ='Listen and type exactly what you hear.';
  static const String writeFromDictationFieldLabel ='Type what you heard';
  static const String summarizeSpokenTextPrompt ='Listen to the recording, then summarize it in one sentence.';
  static const String summarizeSpokenTextFieldLabel ='Your summary';
}
