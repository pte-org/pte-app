import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';

class AudioPromptRepositoryImpl implements AudioPromptRepository {
  AudioPromptRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<String> playAudio({
    required String attemptPublicId,
    required String pinnedItemPublicId,
    required String playRequestId,
  }) {
    return _apiClient.playAudio(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      playRequestId: playRequestId,
    );
  }
}
