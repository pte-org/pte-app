class Question {
  final String id;
  final int part;
  final String questionType;
  final String content;
  final List<String> options;
  final List<String> correctAnswers;
  final String? assetCdnUrl;
  final int? maxPlayCount;

  const Question({
    required this.id,
    required this.part,
    required this.questionType,
    required this.content,
    required this.options,
    required this.correctAnswers,
    this.assetCdnUrl,
    this.maxPlayCount,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      part: json['part'] as int,
      questionType: json['questionType'] as String,
      content: json['content'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctAnswers: List<String>.from(json['correctAnswers'] ?? []),
      assetCdnUrl: json['assetCdnUrl'] as String?,
      maxPlayCount: json['maxPlayCount'] as int?,
    );
  }
}
