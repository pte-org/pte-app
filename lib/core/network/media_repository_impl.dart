import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/media_presign_response.dart';
import 'package:pte_app/core/network/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<MediaPresignResponse> requestPresign(String contentType) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/media/objects',
      data: {'contentType': contentType},
    );
    return MediaPresignResponse.fromJson(response.data!);
  }

  @override
  Future<void> completeUpload(String mediaPublicId) {
    return _apiClient.post<void>('/api/media/objects/$mediaPublicId/complete');
  }
}
