/// Imported listening MC prompts contain transcript + blank line + question.
/// Only the final question belongs on the candidate screen.
String listeningChoiceQuestion(String? promptText) {
  final prompt = (promptText ?? '').replaceAll('\r\n', '\n').trim();
  if (prompt.isEmpty) return '';
  final blocks = prompt.split(RegExp(r'\n\s*\n'));
  if (blocks.length > 1) return blocks.last.trim();
  // Question-only prompts are also supported. A transcript without a question
  // separator must not accidentally become visible as the question.
  final questionStart = RegExp(
    r'^(Which|What|Why|How|Who|Where|When|According|Choose|Select|Complete|'
    r'Identify|The (purpose|speaker|talk|main))\b',
    caseSensitive: false,
  );
  return prompt.length <= 300 &&
          (prompt.endsWith('?') || questionStart.hasMatch(prompt))
      ? prompt
      : '';
}
