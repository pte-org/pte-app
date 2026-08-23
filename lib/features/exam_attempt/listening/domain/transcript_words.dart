/// Splits [text] into words on runs of whitespace, index-stable in
/// appearance order — index 0 is always the first word, independent of
/// line-wrapping. Punctuation stays attached to its word (e.g.
/// `"wonderful."` is one word, not split from its period) — phase-04
/// Design Constraints. Empty/blank [text] yields an empty list.
List<String> splitTranscriptWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  return trimmed.split(RegExp(r'\s+'));
}
