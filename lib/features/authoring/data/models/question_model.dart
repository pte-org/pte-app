import '../../domain/authoring_types.dart';

class QuestionModel {
  QuestionModel({
    required this.publicId,
    required this.pteTaskType,
    required this.section,
    required this.visibility,
    required this.tenantId,
    required this.status,
    required this.title,
    required this.promptText,
    required this.audioPromptRef,
    required this.imagePromptRef,
    required this.referenceAnswerText,
    required this.correctAnswerText,
    required this.minWordCount,
    required this.maxWordCount,
    required this.options,
    required this.skills,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      publicId: json['publicId'] as String,
      pteTaskType: _parseTaskType(json['pteTaskType'] as String),
      section: json['section'] as String,
      visibility: _parseVisibility(json['visibility'] as String),
      tenantId: json['tenantId'] as String?,
      status: json['status'] as String,
      title: json['title'] as String,
      promptText: json['promptText'] as String?,
      audioPromptRef: json['audioPromptRef'] as String?,
      imagePromptRef: json['imagePromptRef'] as String?,
      referenceAnswerText: json['referenceAnswerText'] as String?,
      correctAnswerText: json['correctAnswerText'] as String?,
      minWordCount: json['minWordCount'] as int?,
      maxWordCount: json['maxWordCount'] as int?,
      options: (json['options'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                QuestionOptionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      skills: (json['skills'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }

  final String publicId;
  final PteTaskType pteTaskType;
  final String section;
  final QuestionVisibility visibility;
  final String? tenantId;
  final String status;
  final String title;
  final String? promptText;
  final String? audioPromptRef;
  final String? imagePromptRef;
  final String? referenceAnswerText;
  final String? correctAnswerText;
  final int? minWordCount;
  final int? maxWordCount;
  final List<QuestionOptionModel> options;
  final List<String> skills;

  Question toEntity() {
    return Question(
      publicId: publicId,
      pteTaskType: pteTaskType,
      section: section,
      visibility: visibility,
      tenantId: tenantId,
      status: status,
      title: title,
      promptText: promptText,
      audioPromptRef: audioPromptRef,
      imagePromptRef: imagePromptRef,
      referenceAnswerText: referenceAnswerText,
      correctAnswerText: correctAnswerText,
      minWordCount: minWordCount,
      maxWordCount: maxWordCount,
      options: options
          .map((option) => option.toEntity())
          .toList(growable: false),
      skills: skills,
    );
  }

  static PteTaskType _parseTaskType(String value) {
    return PteTaskType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () => throw FormatException('Unknown PTE task type: $value'),
    );
  }

  static QuestionVisibility _parseVisibility(String value) {
    return QuestionVisibility.values.firstWhere(
      (visibility) => visibility.wireName == value,
      orElse: () =>
          throw FormatException('Unknown question visibility: $value'),
    );
  }
}

class QuestionOptionModel {
  const QuestionOptionModel({
    required this.publicId,
    required this.text,
    required this.correct,
    required this.orderIndex,
  });

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      publicId: json['publicId'] as String,
      text: json['text'] as String,
      correct: json['correct'] as bool,
      orderIndex: json['orderIndex'] as int,
    );
  }

  final String publicId;
  final String text;
  final bool correct;
  final int orderIndex;

  QuestionOption toEntity() {
    return QuestionOption(
      publicId: publicId,
      text: text,
      correct: correct,
      orderIndex: orderIndex,
    );
  }
}
