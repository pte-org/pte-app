import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/authoring/data/repositories/authoring_repository_impl.dart';
import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/domain/blueprint_types.dart';
import 'package:pte_app/features/host_audit/data/repositories/host_audit_repository_impl.dart';
import 'package:pte_app/features/host_users/data/repositories/host_user_repository_impl.dart';
import 'package:pte_app/features/live_proctor/data/repositories/live_proctor_repository_impl.dart';
import 'package:pte_app/features/scheduling/data/repositories/scheduling_repository_impl.dart';
import 'package:pte_app/features/scheduling/domain/session_types.dart';
import 'package:pte_app/features/scoring_review/data/repositories/scoring_review_repository_impl.dart';

import 'mock_backend_harness.dart';

/// Auth and host-side flows through the app's real repositories (and their
/// `fromJson` parsers) against `MockBackendAdapter`, so a drift between the
/// mock's JSON and the app's contracts fails here instead of as a blank
/// screen in mock mode.
void main() {
  late ApiClient apiClient;

  setUp(() => apiClient = createMockBackend().apiClient);

  group('auth', () {
    test(
      'logs every seeded role in with any password and puts the role in the JWT',
      () async {
        const accounts = {
          'student@mock.local': 'STUDENT',
          'host@mock.local': 'HOST_ADMIN',
          'author@mock.local': 'HOST_AUTHOR',
          'proctor@mock.local': 'PROCTOR',
        };
        for (final MapEntry(key: email, value: role) in accounts.entries) {
          final response = await apiClient.post<Map<String, dynamic>>(
            '/api/iam/auth/login',
            data: {'email': email, 'password': 'anything'},
          );
          final claims = decodeJwtClaims(
            response.data!['accessToken'] as String,
          );
          expect(claims.roles, [role], reason: email);
          expect(response.data!['expiresInSeconds'], isA<int>());
        }
      },
    );

    test('rejects unknown and suspended accounts with AuthException', () async {
      for (final email in ['nobody@mock.local', 'suspended@mock.local']) {
        await expectLater(
          apiClient.post<Map<String, dynamic>>(
            '/api/iam/auth/login',
            data: {'email': email, 'password': 'x'},
          ),
          throwsA(isA<AuthException>()),
          reason: email,
        );
      }
    });
  });

  group('host', () {
    test('users, audit and proctor read models parse', () async {
      final users = await HostUserRepositoryImpl(
        apiClient: apiClient,
      ).loadUsers();
      expect(users.where((user) => user.isStudent), isNotEmpty);
      expect(users.where((user) => user.isProctor), isNotEmpty);

      final audit = HostAuditRepositoryImpl(apiClient: apiClient);
      expect(await audit.loadNotifications(), hasLength(4));
      expect(await audit.loadViolations('mock-full-exam'), hasLength(4));

      final proctor = LiveProctorRepositoryImpl(apiClient: apiClient);
      expect(await proctor.loadAssignedSessions(), hasLength(2));
      expect(await proctor.loadViolations('mock-full-exam'), hasLength(4));
    });

    test(
      'authoring creates a question, builds a blueprint and publishes a snapshot',
      () async {
        final authoring = AuthoringRepositoryImpl(apiClient: apiClient);
        expect(await authoring.loadQuestions(), hasLength(4));

        final question = await authoring.createReadAloud(
          const CreateReadAloudInput(
            title: 'New question',
            promptText: 'Read this aloud.',
          ),
        );
        final blueprint = await authoring.createBlueprint(
          CreateBlueprintInput(
            name: 'New blueprint',
            items: [
              BlueprintItemInput(
                questionPublicId: question.publicId,
                section: 'SPEAKING',
                orderIndex: 0,
              ),
            ],
          ),
        );
        final snapshot = await authoring.publishBlueprint(blueprint.publicId);

        expect(snapshot.items.single.taskType, PteTaskType.readAloud);
        expect(
          (await authoring.loadBlueprint(blueprint.publicId)).status,
          'PUBLISHED',
        );
        expect((await authoring.loadSnapshot(snapshot.publicId)).version, 1);
      },
    );

    test(
      'a host-created session becomes takeable once composed and opened',
      () async {
        final scheduling = SchedulingRepositoryImpl(apiClient: apiClient);
        expect(await scheduling.loadSessions(), hasLength(7));
        final options = await scheduling.loadSnapshotOptions(
          'mock-snapshot-foundation',
        );
        expect(
          options.map((option) => option.taskType),
          containsAll(['READ_ALOUD', 'MC_READING_SINGLE', 'WRITE_ESSAY']),
        );

        final now = DateTime.now();
        final created = await scheduling.createSession(
          CreateSessionInput(
            name: 'Host session',
            snapshotPublicId: 'mock-snapshot-foundation',
            opensAt: now.add(const Duration(hours: 1)),
            closesAt: now.add(const Duration(hours: 3)),
          ),
        );
        expect(created.status, SessionStatus.scheduled);
        await scheduling.setComposition(
          created.publicId,
          SetCompositionInput(
            items: [
              const CompositionItemInput(
                taskType: 'MC_READING_SINGLE',
                section: 'READING',
                orderIndex: 0,
              ),
            ],
          ),
        );
        expect(
          (await scheduling.openSession(created.publicId)).status,
          SessionStatus.open,
        );
        await scheduling.enrollStudent(created.publicId, 'mock-user-student');
        await scheduling.assignProctor(created.publicId, 'mock-user-proctor');

        final tasks = await walkAttempt(apiClient, created.publicId);
        expect(tasks.single.taskType, 'MC_READING_SINGLE');
      },
    );

    test('scoring review pages, approves and publishes', () async {
      final scoring = ScoringReviewRepositoryImpl(apiClient: apiClient);
      final firstPage = await scoring.loadPendingReviews('mock-full-exam');
      expect(firstPage.items, hasLength(20));
      expect(firstPage.hasNextPage, isTrue);

      final approved = await scoring.approveReview(
        firstPage.items.first.answerPublicId,
      );
      expect(approved.status, 'HUMAN_REVIEWED');
      expect(
        (await scoring.loadPendingReviews('mock-full-exam')).totalElements,
        24,
      );

      await scoring.requestScoring('mock-closed-last-month');
      await scoring.publishResults('mock-full-exam');
    });
  });
}
