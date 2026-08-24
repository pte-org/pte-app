import '../../domain/scoring_review_types.dart';

class ScoringReviewAnswerModel {
  const ScoringReviewAnswerModel({
    required this.answerPublicId,
    required this.attemptPublicId,
    required this.taskType,
    required this.status,
    required this.rawScore,
  });

  factory ScoringReviewAnswerModel.fromJson(Map<String, dynamic> json) {
    return ScoringReviewAnswerModel(
      answerPublicId: json['answerPublicId'] as String,
      attemptPublicId: json['attemptPublicId'] as String,
      taskType: json['taskType'] as String,
      status: json['status'] as String,
      rawScore: json['rawScore'] as int?,
    );
  }

  final String answerPublicId;
  final String attemptPublicId;
  final String taskType;
  final String status;
  final int? rawScore;

  ScoringReviewAnswer toEntity() => ScoringReviewAnswer(
    answerPublicId: answerPublicId,
    attemptPublicId: attemptPublicId,
    taskType: taskType,
    status: status,
    rawScore: rawScore,
  );
}

class ScoringReviewPageModel {
  const ScoringReviewPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory ScoringReviewPageModel.fromJson(Map<String, dynamic> json) {
    return ScoringReviewPageModel(
      items: (json['items'] as List<dynamic>)
          .map(
            (value) => ScoringReviewAnswerModel.fromJson(
              value as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  final List<ScoringReviewAnswerModel> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  ScoringReviewPage toEntity() => ScoringReviewPage(
    items: items.map((item) => item.toEntity()).toList(growable: false),
    page: page,
    size: size,
    totalElements: totalElements,
    totalPages: totalPages,
  );
}
