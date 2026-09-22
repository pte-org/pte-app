import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/exam_attempt_repository_impl.dart';
import 'package:pte_app/features/exam_attempt/domain/attempt_preflight.dart';
import 'package:pte_app/features/exam_attempt/domain/client_capability_manifest.dart';

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

      final data =
          verify(
                () => apiClient.post<Map<String, dynamic>>(
                  '/api/v1/attempts',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(data['sessionPublicId'], 'session-1');
      expect(data['deviceCheckConfirmed'], isTrue);
      expect(
        data['capabilityManifest'],
        ClientCapabilityManifest.fromRegistry().toJson(),
      );
    },
  );

  test(
    'defaults to an unconfirmed device check for the first start request',
    () async {
      await repository.startOrResumeAttempt('session-1');

      final data =
          verify(
                () => apiClient.post<Map<String, dynamic>>(
                  '/api/v1/attempts',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(data['sessionPublicId'], 'session-1');
      expect(data['deviceCheckConfirmed'], isFalse);
      expect(
        data['capabilityManifest'],
        ClientCapabilityManifest.fromRegistry().toJson(),
      );
    },
  );

  test('preflight sends the same registry capability manifest', () async {
    when(
      () => apiClient.post<Map<String, dynamic>>(
        '/api/v1/attempts/preflight',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/attempts/preflight'),
        statusCode: 200,
        data: {'canStart': true, 'missingCapabilities': <String>[]},
      ),
    );

    final result = await repository.preflight('session-1');
    expect(result, isA<AttemptPreflight>());
    final data =
        verify(
              () => apiClient.post<Map<String, dynamic>>(
                '/api/v1/attempts/preflight',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(data['sessionPublicId'], 'session-1');
    expect(
      data['capabilityManifest'],
      ClientCapabilityManifest.fromRegistry().toJson(),
    );
  });
}
