import 'package:pte_app/core/constants/task_type_meta.dart';
import 'listening_choice_prompt.dart';

/// Candidate-visible text; the underlying task data remains intact.
/// Listening transcripts belong only to Type In and Incorrect Words tasks.
String candidatePromptText(String? taskType, String? promptText) {
  final prompt = (promptText ?? '').trim();
  return switch (TaskTypeCodes.canonicalize(taskType)) {
    TaskTypeCodes.summarizeSpokenText ||
    TaskTypeCodes.highlightCorrectSummary ||
    TaskTypeCodes.selectMissingWord ||
    TaskTypeCodes.writeFromDictation => '',
    TaskTypeCodes.mcListeningSingle ||
    TaskTypeCodes.mcListeningMultiple => listeningChoiceQuestion(prompt),
    _ => prompt,
  };
}
