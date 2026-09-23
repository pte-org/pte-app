import 'dart:io';

import 'package:dio/dio.dart';

import 'package:pte_app/core/config/app_config.dart';
import 'package:pte_app/core/network/cloudinary_upload_result.dart';

/// Unauthenticated multipart client for direct signed Cloudinary uploads.
///
/// The short-lived Cloudinary signature is the credential for this request.
/// The app bearer token must never be sent to Cloudinary, so this client uses
/// its own Dio instance without the gateway interceptors.
class RawUploadClient {
  RawUploadClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
            ),
          );

  final Dio _dio;

  List<Interceptor> get interceptors => List.unmodifiable(_dio.interceptors);

  /// Reads [file] from disk for every call, including retries after a stale
  /// signature, instead of keeping the recording in memory.
  Future<CloudinaryUploadResult> upload({
    required String uploadUrl,
    required File file,
    required String contentType,
    required String apiKey,
    required String timestamp,
    required String signature,
    required String folder,
    required String publicId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        uploadUrl,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.uri.pathSegments.last,
            contentType: DioMediaType.parse(contentType),
          ),
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
          'folder': folder,
          'public_id': publicId,
        }),
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      final body = response.data;
      if (body == null) {
        throw const RawUploadException(
          looksExpired: false,
          message: 'Cloudinary returned an empty response',
        );
      }
      return CloudinaryUploadResult.fromJson(body);
    } on DioException catch (e) {
      throw RawUploadException(
        looksExpired: _looksLikeExpiredUrl(e),
        message: e.message ?? 'Upload failed',
      );
    }
  }

  bool _looksLikeExpiredUrl(DioException e) {
    final statusCode = e.response?.statusCode;
    return statusCode == 400 || statusCode == 401 || statusCode == 403;
  }
}

class RawUploadException implements Exception {
  const RawUploadException({required this.looksExpired, required this.message});

  final bool looksExpired;
  final String message;

  @override
  String toString() =>
      'RawUploadException: $message (looksExpired=$looksExpired)';
}
