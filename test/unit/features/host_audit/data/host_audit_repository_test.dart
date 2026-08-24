import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/host_audit/data/models/host_audit_models.dart';
import 'package:pte_app/features/host_audit/data/repositories/host_audit_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test(
    'maps strict timestamps and uses exact read-only gateway paths',
    () async {
      final apiClient = _MockApiClient();
      final repository = HostAuditRepositoryImpl(apiClient: apiClient);
      when(
        () => apiClient.get<List<dynamic>>('/api/notification/notifications'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: [
            {
              'publicId': 'notification-1',
              'recipientEmail': 'student@example.com',
              'notificationType': 'SESSION_OPENED',
              'subject': 'Session available',
              'status': 'SENT',
              'sentAt': '2026-07-28T01:02:03Z',
            },
          ],
        ),
      );
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

      final notifications = await repository.loadNotifications();
      final violations = await repository.loadViolations('session-1');

      expect(notifications.single.sentAt, DateTime.utc(2026, 7, 28, 1, 2, 3));
      expect(violations.single.sequenceNo, 1);
      expect(violations.single.hash, 'abc123');
    },
  );

  test('malformed timestamps fail mapping instead of using current time', () {
    expect(
      () => NotificationAuditModel.fromJson({
        'publicId': 'notification-1',
        'recipientEmail': 'student@example.com',
        'notificationType': 'SESSION_OPENED',
        'subject': 'Session available',
        'status': 'SENT',
        'sentAt': 'not-a-timestamp',
      }),
      throwsFormatException,
    );
    expect(
      () => ViolationAuditModel.fromJson({
        'publicId': 'violation-1',
        'attemptPublicId': 'attempt-1',
        'violationType': 'TAB_SWITCH',
        'detail': 'Window focus changed',
        'sequenceNo': 1,
        'hash': 'abc123',
        'detectedAt': null,
      }),
      throwsFormatException,
    );
  });
}
