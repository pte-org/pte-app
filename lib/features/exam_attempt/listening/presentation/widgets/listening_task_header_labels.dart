import 'package:pte_app/features/exam_attempt/listening/constants/listening_strings.dart';

/// Maps a listening `TaskView.taskType` to its `ExamTaskHeaderBanner` title —
/// mirrors `reading_task_header_labels.dart`'s shape, kept as a separate
/// per-feature mapping (each feature owns its own title strings) even
/// though the banner widget itself is shared.
String listeningTaskHeaderTitle(String taskType) {
  return switch (taskType) {
    'WRITE_FROM_DICTATION' => ListeningStrings.headerTitleWriteFromDictation,
    'SUMMARIZE_SPOKEN_TEXT' => ListeningStrings.headerTitleSummarizeSpokenText,
    'MC_LISTENING_SINGLE' => ListeningStrings.headerTitleMcListeningSingle,
    'MC_LISTENING_MULTIPLE' => ListeningStrings.headerTitleMcListeningMultiple,
    'SELECT_MISSING_WORD' => ListeningStrings.headerTitleSelectMissingWord,
    'HIGHLIGHT_INCORRECT_WORDS' => ListeningStrings.headerTitleHighlightIncorrectWords,
    'HIGHLIGHT_CORRECT_SUMMARY' => ListeningStrings.headerTitleHighlightCorrectSummary,
    'FILL_IN_THE_BLANKS_TYPE_IN' => ListeningStrings.headerTitleFillBlanksListening,
    _ => '',
  };
}
