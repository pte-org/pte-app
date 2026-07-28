/// `POST /api/media/objects` response — a fresh presigned upload target.
/// Re-requested (never cached across a retry-after-expiry) whenever the
/// coordinator needs a new one (phase-06 Design Constraints).
class MediaPresignResponse {
  const MediaPresignResponse({required this.mediaPublicId, required this.uploadUrl, required this.expiresInSeconds});

  final String mediaPublicId;
  final String uploadUrl;
  final int expiresInSeconds;

  factory MediaPresignResponse.fromJson(Map<String, dynamic> json) {
    return MediaPresignResponse(
      mediaPublicId: json['mediaPublicId'] as String,
      uploadUrl: json['uploadUrl'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
    );
  }
}
