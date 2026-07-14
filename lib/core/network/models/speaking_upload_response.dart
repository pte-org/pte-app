/// DTO mapping from BE `SpeakingUploadResponse` record.
class SpeakingUploadResponse {
  const SpeakingUploadResponse({
    required this.questionId,
    required this.audioUrl,
    required this.fileSize,
    required this.mimeType,
  });

  factory SpeakingUploadResponse.fromJson(Map<String, dynamic> json) {
    return SpeakingUploadResponse(
      questionId: (json['questionId'] as num).toInt(),
      audioUrl: json['audioUrl'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      mimeType: json['mimeType'] as String,
    );
  }

  final int questionId;
  final String audioUrl;
  final int fileSize;
  final String mimeType;
}
