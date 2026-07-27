import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Thin, deliberately uninterceptored `PUT` client for presigned MinIO
/// uploads. The presigned URL itself is the credential (900s TTL) —
/// attaching the app's bearer `Authorization` header would send it to a
/// different origin than the API gateway for no reason (phase-06 Design
/// Constraints). Never reuse `ApiClient`'s gateway `Dio` instance for this
/// call; this class's [Dio] carries zero interceptors, always.
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

  /// Exposed so tests can assert directly on the interceptor list (e.g.
  /// confirming no auth interceptor was ever attached) rather than only
  /// inferring it from a successful mocked response.
  List<Interceptor> get interceptors => List.unmodifiable(_dio.interceptors);

  /// Throws [RawUploadException] on any non-2xx response. [file] is
  /// re-read from disk on every call (including a retry after re-presign)
  /// rather than buffered — the recording is never held only in memory
  /// (phase-06 Design Constraints).
  Future<void> putFile(String uploadUrl, File file, {required String contentType}) async {
    try {
      await _dio.put<void>(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {Headers.contentTypeHeader: contentType, Headers.contentLengthHeader: await file.length()},
        ),
      );
    } on DioException catch (e) {
      throw RawUploadException(looksExpired: _looksLikeExpiredUrl(e), message: e.message ?? 'Upload failed');
    }
  }

  /// MinIO returns its own error body for a stale/invalid presigned URL —
  /// distinct from `pte-api`'s `ApiResponse` envelope, since this request
  /// never touches the gateway. 403 (SignatureDoesNotMatch/AccessDenied)
  /// and 400 (expired request) are the shapes a stale presign takes; any
  /// other failure (including no response at all) is a generic upload
  /// failure, not an expiry signal.
  bool _looksLikeExpiredUrl(DioException e) {
    final statusCode = e.response?.statusCode;
    return statusCode == 403 || statusCode == 400;
  }
}

class RawUploadException implements Exception {
  const RawUploadException({required this.looksExpired, required this.message});

  final bool looksExpired;
  final String message;

  @override
  String toString() => 'RawUploadException: $message (looksExpired=$looksExpired)';
}
