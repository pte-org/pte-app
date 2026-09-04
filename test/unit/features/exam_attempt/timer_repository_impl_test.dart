import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
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

  test('fetchTimerState delegates to ApiClient.fetchTimerState and parses the response', () async {
    // Routed through ApiClient's own dedicated method (not the generic
    // get()) so a 409 comes back typed as AttemptAlreadyCompleteException
    // rather than a bare ConflictException (plans/phat-speaking-dynamic-
    // prep-timing follow-up).
    when(() => apiClient.fetchTimerState('attempt-1')).thenAnswer(
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
    verify(() => apiClient.fetchTimerState('attempt-1')).called(1);
  });

  test('propagates the ApiClient exception instead of swallowing it', () async {
    when(() => apiClient.fetchTimerState('attempt-1')).thenThrow(Exception('network down'));

    expect(() => repository.fetchTimerState('attempt-1'), throwsA(isA<Exception>()));
  });

  test('propagates AttemptAlreadyCompleteException specifically, not just a generic Exception', () async {
    when(
      () => apiClient.fetchTimerState('attempt-1'),
    ).thenThrow(const AttemptAlreadyCompleteException('ATTEMPT_ALREADY_COMPLETE'));

    expect(
      () => repository.fetchTimerState('attempt-1'),
      throwsA(isA<AttemptAlreadyCompleteException>()),
    );
  });
}
