import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/cloudinary_upload_result.dart';
import 'package:pte_app/core/network/media_presign_response.dart';
import 'package:pte_app/core/network/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<MediaPresignResponse> requestPresign(
    String contentType, {
    int? sizeBytes,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/objects',
      data: {
        'contentType': contentType,
        'assetKind': 'STUDENT_RESPONSE_AUDIO',
        'sizeBytes': sizeBytes ?? 1,
      },
    );
    return MediaPresignResponse.fromJson(response.data!);
  }

  @override
  Future<void> completeUpload(
    String mediaPublicId, [
    CloudinaryUploadResult? upload,
  ]) {
    if (upload == null) {
      throw StateError(
        'Cloudinary upload metadata is required to complete media',
      );
    }
    return _apiClient.post<void>(
      '/api/v1/objects/$mediaPublicId/complete',
      data: upload.toApiJson(),
    );
  }
}
