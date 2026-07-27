import 'media_presign_response.dart';

/// Presign/complete only — both go through Phase 1's normal authenticated
/// `ApiClient`. The raw `PUT {uploadUrl}` itself is deliberately NOT part
/// of this repository (phase-06 Design Constraints: it must never go
/// through the authenticated gateway `Dio` instance) — see
/// `RawUploadClient`.
abstract class MediaRepository {
  Future<MediaPresignResponse> requestPresign(String contentType);

  Future<void> completeUpload(String mediaPublicId);
}
