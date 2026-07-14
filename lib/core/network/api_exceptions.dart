import 'package:dio/dio.dart';

/// Base type for all API-layer failures. Bloc and the sync engine (Phase 5)
/// catch these — never raw [DioException] — to decide retry vs. mark-failed.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Forbidden']);
}

/// 409 — per FR-06, the exam part has already closed; the sync engine must
/// not retry this, the answer is permanently rejected.
class ConflictException extends ApiException {
  const ConflictException([super.message = 'Conflict']);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Server error']);
}

/// Timeout, DNS failure, no connection — distinct from server-side failures
/// because the sync engine should keep retrying these, not give up.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Network error']);
}

/// Maps a [DioException] to the corresponding [ApiException] subtype.
ApiException mapDioExceptionToApiException(DioException error) {
  final statusCode = error.response?.statusCode;
  switch (statusCode) {
    case 401:
      return const UnauthorizedException();
    case 403:
      return const ForbiddenException();
    case 409:
      return const ConflictException();
  }
  if (statusCode != null && statusCode >= 500) {
    return const ServerException();
  }
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    default:
      return ServerException(error.message ?? 'Unknown error');
  }
}
