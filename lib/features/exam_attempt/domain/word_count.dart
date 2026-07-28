/// Counts words in [text] by splitting on runs of whitespace, ignoring
/// leading/trailing whitespace so multiple spaces or line breaks don't
/// inflate the count. Guidance-only utility (phase-05 Design Constraints)
/// — never used to gate submission or navigation.
int countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}
