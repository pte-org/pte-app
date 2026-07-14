import 'package:aptis_app/core/network/api_client.dart';
import 'package:aptis_app/core/network/models/submit_answer_request.dart';
import 'package:aptis_app/features/speaking/domain/repositories/speaking_repository.dart';

/// Concrete implementation of [SpeakingRepository] backed by [ApiClient].
class SpeakingRepositoryImpl implements SpeakingRepository {
  const SpeakingRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  static const String _questionType = 'SPEAKING';

  @override
  Future<String> uploadRecording({
    required int attemptId,
    required int questionId,
    required List<int> audioBytes,
    required String mimeType,
    String filename = 'recording.webm',
  }) async {
    final response = await _apiClient.uploadSpeakingRecording(
      attemptId: attemptId,
      questionId: questionId,
      bytes: audioBytes,
      mimeType: mimeType,
      filename: filename,
    );
    return response.audioUrl;
  }

  @override
  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    required String audioUrl,
  }) {
    return _apiClient.submitSpeakingAnswer(
      attemptId: attemptId,
      request: SubmitAnswerRequest(
        questionId: questionId,
        questionType: _questionType,
        content: audioUrl,
      ),
    );
  }
}
