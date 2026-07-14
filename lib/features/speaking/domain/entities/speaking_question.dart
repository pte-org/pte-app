import 'package:flutter/foundation.dart';

@immutable
class SpeakingQuestion {
  final int? id; // null when using mock data, real questionId from BE otherwise
  final String partLabel;
  final String prompt;
  final bool showsImage;
  final List<String>? imageUrls;
  final List<String>? subPrompts;

  const SpeakingQuestion({
    this.id,
    required this.partLabel,
    required this.prompt,
    this.showsImage = false,
    this.imageUrls,
    this.subPrompts,
  });
}
