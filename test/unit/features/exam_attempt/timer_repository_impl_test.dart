import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/timer_repository_impl.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late TimerRepositoryImpl repository;

  setUp(() {
    apiClient = _MockApiClient();
    repository = TimerRepositoryImpl(apiClient: apiClient);
  });

  test('fetchTimerState GETs /api/exam-delivery/attempts/{id}/timer and parses the response', () async {
    when(() => apiClient.get<Map<String, dynamic>>('/api/exam-delivery/attempts/attempt-1/timer')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/exam-delivery/attempts/attempt-1/timer'),
        statusCode: 200,
        data: {
          'phase': 'RESPONSE',
          'currentOrderIndex': 2,
          'prepDeadline': '2026-01-01T00:00:30.000Z',
          'responseDeadline': '2026-01-01T00:01:30.000Z',
          'serverNow': '2026-01-01T00:00:45.000Z',
        },
      ),
    );

    final response = await repository.fetchTimerState('attempt-1');

    expect(response.phase, TimerPhase.response);
    expect(response.currentOrderIndex, 2);
    verify(() => apiClient.get<Map<String, dynamic>>('/api/exam-delivery/attempts/attempt-1/timer')).called(1);
  });

  test('propagates the ApiClient exception instead of swallowing it', () async {
    when(
      () => apiClient.get<Map<String, dynamic>>('/api/exam-delivery/attempts/attempt-1/timer'),
    ).thenThrow(Exception('network down'));

    expect(() => repository.fetchTimerState('attempt-1'), throwsA(isA<Exception>()));
  });
}
