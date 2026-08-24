import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/live_proctor/data/repositories/live_proctor_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test(
    'loads assigned sessions from the authenticated proctor endpoint',
    () async {
      final apiClient = _MockApiClient();
      final repository = LiveProctorRepositoryImpl(apiClient: apiClient);
      when(
        () => apiClient.get<List<dynamic>>(
          '/api/scheduling/proctor-assignments/me',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: [
            {
              'assignmentPublicId': 'assignment-1',
              'sessionPublicId': 'session-1',
              'name': 'July mock exam',
              'opensAt': '2026-07-28T01:02:03Z',
              'closesAt': '2026-07-28T03:02:03Z',
              'status': 'OPEN',
            },
          ],
        ),
      );

      final sessions = await repository.loadAssignedSessions();

      expect(sessions.single.assignmentPublicId, 'assignment-1');
      expect(sessions.single.sessionPublicId, 'session-1');
      expect(sessions.single.opensAt, DateTime.utc(2026, 7, 28, 1, 2, 3));
    },
  );

  test(
    'loads recovery violations using the selected exam session id',
    () async {
      final apiClient = _MockApiClient();
      final repository = LiveProctorRepositoryImpl(apiClient: apiClient);
      when(
        () => apiClient.get<List<dynamic>>(
          '/api/proctor/exam-sessions/session-1/violations',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: [
            {
              'publicId': 'violation-1',
              'attemptPublicId': 'attempt-1',
              'violationType': 'TAB_SWITCH',
              'detail': 'Window focus changed',
              'sequenceNo': 1,
              'hash': 'abc123',
              'detectedAt': '2026-07-28T01:03:04Z',
            },
          ],
        ),
      );

      final violations = await repository.loadViolations('session-1');

      expect(violations.single.publicId, 'violation-1');
      expect(violations.single.type.wireName, 'TAB_SWITCH');
      expect(violations.single.detectedAt, DateTime.utc(2026, 7, 28, 1, 3, 4));
    },
  );
}
