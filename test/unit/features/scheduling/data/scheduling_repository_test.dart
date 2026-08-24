import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/scheduling/data/repositories/scheduling_repository_impl.dart';
import 'package:pte_app/features/scheduling/domain/session_types.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late SchedulingRepositoryImpl repository;

  final sessionJson = <String, dynamic>{
    'publicId': 'session-1',
    'name': 'Mock exam',
    'tenantId': 'tenant-1',
    'snapshotPublicId': 'snap-1',
    'opensAt': '2026-07-29T08:00:00Z',
    'closesAt': '2026-07-29T10:00:00Z',
    'status': 'SCHEDULED',
    'composition': <Map<String, dynamic>>[],
  };

  setUp(() {
    apiClient = _MockApiClient();
    repository = SchedulingRepositoryImpl(apiClient: apiClient);
  });

  test(
    'list, get, and create use exact scheduling gateway contracts',
    () async {
      when(
        () => apiClient.get<List<dynamic>>('/api/scheduling/sessions'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: [sessionJson],
        ),
      );
      when(
        () => apiClient.get<Map<String, dynamic>>(
          '/api/scheduling/sessions/session-1',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: sessionJson,
        ),
      );
      Object? payload;
      when(
        () => apiClient.post<Map<String, dynamic>>(
          '/api/scheduling/sessions',
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        payload = invocation.namedArguments[#data];
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: sessionJson,
        );
      });

      expect((await repository.loadSessions()).single.publicId, 'session-1');
      expect(
        (await repository.loadSession('session-1')).status.canOpen,
        isTrue,
      );
      await repository.createSession(
        CreateSessionInput(
          name: 'Mock exam',
          snapshotPublicId: 'snap-1',
          opensAt: DateTime.parse('2026-07-29T08:00:00Z'),
          closesAt: DateTime.parse('2026-07-29T10:00:00Z'),
        ),
      );

      expect(payload, {
        'name': 'Mock exam',
        'snapshotPublicId': 'snap-1',
        'opensAt': '2026-07-29T08:00:00.000Z',
        'closesAt': '2026-07-29T10:00:00.000Z',
      });
    },
  );

  test(
    'composition and lifecycle mutations use exact methods and paths',
    () async {
      Object? compositionPayload;
      when(
        () => apiClient.put<Map<String, dynamic>>(
          '/api/scheduling/sessions/session-1/composition',
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        compositionPayload = invocation.namedArguments[#data];
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: sessionJson,
        );
      });
      for (final action in ['open', 'close']) {
        when(
          () => apiClient.post<Map<String, dynamic>>(
            '/api/scheduling/sessions/session-1/$action',
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: sessionJson,
          ),
        );
      }

      await repository.setComposition(
        'session-1',
        SetCompositionInput(
          items: const [
            CompositionItemInput(
              taskType: 'READ_ALOUD',
              section: 'SPEAKING',
              orderIndex: 0,
              timingOverrideSeconds: 60,
            ),
          ],
        ),
      );
      await repository.openSession('session-1');
      await repository.closeSession('session-1');

      expect(compositionPayload, {
        'items': [
          {
            'taskType': 'READ_ALOUD',
            'section': 'SPEAKING',
            'orderIndex': 0,
            'timingOverrideSeconds': 60,
          },
        ],
      });
    },
  );

  test(
    'snapshot options are read without importing authoring models',
    () async {
      when(
        () => apiClient.get<Map<String, dynamic>>(
          '/api/authoring/snapshots/snap-1',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'items': [
              {
                'taskType': 'READ_ALOUD',
                'section': 'SPEAKING',
                'title': 'Read this aloud',
                'orderIndex': 0,
              },
            ],
          },
        ),
      );

      final options = await repository.loadSnapshotOptions('snap-1');

      expect(options.single.taskType, 'READ_ALOUD');
      expect(options.single.section, 'SPEAKING');
    },
  );
}
