/// One piece of a fill-in-the-blanks passage split by [parseBlankPrompt].
sealed class PromptSegment {}

/// A run of literal passage text between (or around) gaps.
class PromptTextSegment extends PromptSegment {
  PromptTextSegment(this.text);

  final String text;
}

/// A gap at [gapIndex] — the caller renders whatever interactive widget
/// (drag target, dropdown) belongs at this position.
class PromptGapSegment extends PromptSegment {
  PromptGapSegment(this.gapIndex);

  final int gapIndex;
}

final RegExp _gapMarkerPattern = RegExp(r'\{\{(\d+)\}\}');

/// Splits [promptText] on `{{n}}` gap markers into alternating text/gap
/// segments, in source order. A [promptText] with no markers returns a
/// single [PromptTextSegment]. Malformed markers can't occur with this
/// pattern (only digits match inside the braces) — an unparseable digit
/// run simply isn't matched and stays literal text, so this never throws.
List<PromptSegment> parseBlankPrompt(String promptText) {
  final segments = <PromptSegment>[];
  var cursor = 0;
  for (final match in _gapMarkerPattern.allMatches(promptText)) {
    if (match.start > cursor) {
      segments.add(PromptTextSegment(promptText.substring(cursor, match.start)));
    }
    segments.add(PromptGapSegment(int.parse(match.group(1)!)));
    cursor = match.end;
  }
  if (cursor < promptText.length) {
    segments.add(PromptTextSegment(promptText.substring(cursor)));
  }
  if (segments.isEmpty) {
    segments.add(PromptTextSegment(promptText));
  }
  return segments;
}
