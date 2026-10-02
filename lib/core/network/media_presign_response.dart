/// `POST /api/v1/objects` response — a fresh presigned upload target.
/// Re-requested (never cached across a retry-after-expiry) whenever the
/// coordinator needs a new one (phase-06 Design Constraints).
class MediaPresignResponse {
  const MediaPresignResponse({
    required this.mediaPublicId,
    required this.uploadUrl,
    required this.expiresInSeconds,
    this.publicId = '',
    this.apiKey = '',
    this.timestamp = '',
    this.signature = '',
    this.folder = '',
    this.resourceType = 'video',
  });

  final String mediaPublicId;
  final String publicId;
  final String uploadUrl;
  final String apiKey;
  final String timestamp;
  final String signature;
  final String folder;
  final String resourceType;
  final int expiresInSeconds;

  factory MediaPresignResponse.fromJson(Map<String, dynamic> json) {
    return MediaPresignResponse(
      mediaPublicId: json['mediaPublicId'] as String,
      publicId: json['publicId'] as String,
      uploadUrl: json['uploadUrl'] as String,
      apiKey: json['apiKey'] as String,
      timestamp: json['timestamp'] as String,
      signature: json['signature'] as String,
      folder: json['folder'] as String,
      resourceType: json['resourceType'] as String,
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
    );
  }
}
