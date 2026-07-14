/// Skeleton DTO for the answer-submit endpoint response — fields must be
/// reconciled against the real `aptis-be` contract (DC-05 idempotency).
class AnswerSubmitResponse {
  const AnswerSubmitResponse({
    required this.questionId,
    required this.acceptedAt,
  });

  factory AnswerSubmitResponse.fromJson(Map<String, dynamic> json) {
    return AnswerSubmitResponse(
      questionId: json['question_id'] as String,
      acceptedAt: DateTime.parse(json['accepted_at'] as String),
    );
  }

  final String questionId;
  final DateTime acceptedAt;
}
