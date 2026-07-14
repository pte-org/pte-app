/// Request body mapping to BE `SubmitAnswerRequest` record.
class SubmitAnswerRequest {
  const SubmitAnswerRequest({
    required this.questionId,
    required this.questionType,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionType': questionType,
      'content': content,
    };
  }

  final int questionId;

  /// Matches BE `questionType` column — e.g. `"SPEAKING"`.
  final String questionType;

  /// For speaking answers, this is the Cloudinary `audioUrl` returned by the
  /// upload endpoint.
  final String content;
}
