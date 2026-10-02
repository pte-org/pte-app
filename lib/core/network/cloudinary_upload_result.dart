/// Metadata returned by Cloudinary after a direct signed upload.
class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.publicId,
    required this.assetId,
    required this.secureUrl,
    required this.resourceType,
    required this.bytes,
    required this.version,
    required this.signature,
    this.format,
    this.durationSeconds,
  });

  final String publicId;
  final String assetId;
  final String secureUrl;
  final String resourceType;
  final String? format;
  final int bytes;
  final int? durationSeconds;
  final int version;
  final String signature;

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    final duration = json['duration'];
    return CloudinaryUploadResult(
      publicId: json['public_id'] as String,
      assetId: json['asset_id'] as String,
      secureUrl: json['secure_url'] as String,
      resourceType: json['resource_type'] as String,
      format: json['format'] as String?,
      bytes: (json['bytes'] as num).toInt(),
      durationSeconds: duration is num ? duration.round() : null,
      version: (json['version'] as num).toInt(),
      signature: json['signature'] as String,
    );
  }

  Map<String, dynamic> toApiJson() => {
    'publicId': publicId,
    'assetId': assetId,
    'secureUrl': secureUrl,
    'resourceType': resourceType,
    'format': format,
    'bytes': bytes,
    'durationSeconds': durationSeconds,
    'version': version,
    'signature': signature,
  };
}
