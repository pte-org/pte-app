import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/exam_attempt_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late ExamAttemptRepositoryImpl repository;

  setUp(() {
    apiClient = _MockApiClient();
    repository = ExamAttemptRepositoryImpl(apiClient: apiClient);
    when(
      () => apiClient.post<Map<String, dynamic>>(
        '/api/v1/attempts',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/attempts'),
        statusCode: 200,
        data: {
          'attemptPublicId': 'attempt-1',
          'attemptStatus': 'IN_PROGRESS',
          'completed': true,
        },
      ),
    );
  });

  test(
    'sends a confirmed device check when the pre-exam check is complete',
    () async {
      await repository.startOrResumeAttempt(
        'session-1',
        deviceCheckConfirmed: true,
      );

      verify(
        () => apiClient.post<Map<String, dynamic>>(
          '/api/v1/attempts',
          data: {'sessionPublicId': 'session-1', 'deviceCheckConfirmed': true},
        ),
      ).called(1);
    },
  );

  test(
    'defaults to an unconfirmed device check for the first start request',
    () async {
      await repository.startOrResumeAttempt('session-1');

      verify(
        () => apiClient.post<Map<String, dynamic>>(
          '/api/v1/attempts',
          data: {'sessionPublicId': 'session-1', 'deviceCheckConfirmed': false},
        ),
      ).called(1);
    },
  );
}
