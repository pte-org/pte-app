import 'package:pte_app/core/network/media_presign_response.dart';
import 'package:pte_app/core/network/cloudinary_upload_result.dart';

/// Presign/complete only — both go through Phase 1's normal authenticated
/// `ApiClient`. The raw `PUT {uploadUrl}` itself is deliberately NOT part
/// of this repository (phase-06 Design Constraints: it must never go
/// through the authenticated gateway `Dio` instance) — see
/// `RawUploadClient`.
abstract class MediaRepository {
  Future<MediaPresignResponse> requestPresign(
    String contentType, {
    int? sizeBytes,
  });

  Future<void> completeUpload(
    String mediaPublicId, [
    CloudinaryUploadResult? upload,
  ]);
}
