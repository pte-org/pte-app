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

  static const String headerTitleWriteFromDictation = 'Listening: Write From Dictation';
  static const String headerTitleSummarizeSpokenText = 'Listening: Summarize Spoken Text';
  static const String headerTitleMcListeningSingle = 'Listening: Multiple Choice, Single Answer';
  static const String headerTitleMcListeningMultiple = 'Listening: Multiple Choice, Multiple Answers';
  static const String headerTitleSelectMissingWord = 'Listening: Select Missing Word';
  static const String headerTitleHighlightIncorrectWords = 'Listening: Highlight Incorrect Words';
  static const String headerTitleHighlightCorrectSummary = 'Listening: Highlight Correct Summary';
  static const String headerTitleFillBlanksListening = 'Listening: Fill in the Blanks';
}
