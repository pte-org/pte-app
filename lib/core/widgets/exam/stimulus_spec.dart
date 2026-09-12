/// A data-only part of the content shown before the response control.
enum StimulusPartKind { passage, text, audio, image, transcript }

class StimulusPart {
  const StimulusPart({required this.kind, required this.content, this.label});

  final StimulusPartKind kind;
  final String content;
  final String? label;
}

/// Supports one or more stimulus parts, including audio + transcript/text.
class StimulusSpec {
  const StimulusSpec({this.parts = const []});

  final List<StimulusPart> parts;

  bool get isEmpty => parts.isEmpty;
  bool get isCompound => parts.length > 1;
}
