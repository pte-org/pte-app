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
        () => apiClient.get<Map<String, dynamic>>('/api/scheduling/sessions/session-1'),
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
          skills: {ExamSkill.speaking, ExamSkill.writing},
          opensAt: DateTime.parse('2026-07-29T08:00:00Z'),
          closesAt: DateTime.parse('2026-07-29T10:00:00Z'),
        ),
      );

      expect(payload, {
        'name': 'Mock exam',
        'skills': ['SPEAKING', 'WRITING'],
        'opensAt': '2026-07-29T08:00:00.000Z',
        'closesAt': '2026-07-29T10:00:00.000Z',
      });
    },
  );

  test('lifecycle mutations use exact methods and paths', () async {
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

    await repository.openSession('session-1');
    await repository.closeSession('session-1');
  });

  test(
    'assign/unassign/list Class use exact /sessions/{id}/classes contracts',
    () async {
      final assignmentJson = <String, dynamic>{
        'sessionPublicId': 'session-1',
        'classPublicId': 'class-1',
      };
      when(
        () => apiClient.get<List<dynamic>>('/api/scheduling/sessions/session-1/classes'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: [assignmentJson],
        ),
      );
      Object? assignPayload;
      when(
        () => apiClient.post<Map<String, dynamic>>(
          '/api/scheduling/sessions/session-1/classes',
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        assignPayload = invocation.namedArguments[#data];
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: assignmentJson,
        );
      });
      when(
        () => apiClient.delete<void>('/api/scheduling/sessions/session-1/classes/class-1'),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      final assigned = await repository.loadAssignedClasses('session-1');
      expect(assigned.single.classPublicId, 'class-1');

      final assignment = await repository.assignClass('session-1', 'class-1');
      expect(assignment.classPublicId, 'class-1');
      expect(assignPayload, {'classPublicId': 'class-1'});

      await repository.unassignClass('session-1', 'class-1');
      verify(
        () => apiClient.delete<void>('/api/scheduling/sessions/session-1/classes/class-1'),
      ).called(1);
    },
  );
}
