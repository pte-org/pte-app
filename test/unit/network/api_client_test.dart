import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = _MockDio();
    apiClient = ApiClient(dio: dio);
  });

  DioException errorWithStatus(int? statusCode, {DioExceptionType type = DioExceptionType.badResponse}) {
    final requestOptions = RequestOptions(path: '/api/whatever');
    return DioException(
      requestOptions: requestOptions,
      type: type,
      response: statusCode == null
          ? null
          : Response(requestOptions: requestOptions, statusCode: statusCode),
    );
  }

  test('post() returns response data on success', () async {
    final response = Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/api/x'),
      data: {'ok': true},
      statusCode: 200,
    );
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
        .thenAnswer((_) async => response);

    final result = await apiClient.post<Map<String, dynamic>>('/api/x', data: {'a': 1});

    expect(result.data, {'ok': true});
  });

  test('401 response maps to AuthException', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
        .thenThrow(errorWithStatus(401));

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<AuthException>()),
    );
  });

  test('400 response maps to ValidationException', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
        .thenThrow(errorWithStatus(400));

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<ValidationException>()),
    );
  });

  test('429 response maps to RateLimitException, never AuthException/ValidationException', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
        .thenThrow(errorWithStatus(429));

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<RateLimitException>()),
    );
  });

  test('connection error (no response) maps to NetworkException', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
        .thenThrow(errorWithStatus(null, type: DioExceptionType.connectionError));

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<NetworkException>()),
    );
  });

  test('unrecognized 500 maps to UnknownApiException, not silently swallowed', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
        .thenThrow(errorWithStatus(500));

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<UnknownApiException>()),
    );
  });

  test('409 response maps to ConflictException carrying the response body message', () async {
    final requestOptions = RequestOptions(path: '/api/x');
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 409,
          data: {'success': false, 'data': null, 'message': 'NOT_CURRENT_TASK'},
        ),
      ),
    );

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<ConflictException>().having((e) => e.message, 'message', 'NOT_CURRENT_TASK')),
    );
  });

  test('submitAnswer() posts to the attempt answers endpoint with pinnedItemPublicId and payload', () async {
    final response = Response<void>(requestOptions: RequestOptions(path: '/api/x'), statusCode: 200);
    when(() => dio.post<void>(any(), data: any(named: 'data'))).thenAnswer((_) async => response);

    await apiClient.submitAnswer(attemptPublicId: 'attempt-1', pinnedItemPublicId: 'item-1', payload: 'hello');

    final captured = verify(() => dio.post<void>(captureAny(), data: captureAny(named: 'data'))).captured;
    expect(captured[0], '/api/exam-delivery/attempts/attempt-1/answers');
    expect(captured[1], {'pinnedItemPublicId': 'item-1', 'payload': 'hello'});
  });
}
