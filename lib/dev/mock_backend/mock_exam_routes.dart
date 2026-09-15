import 'package:pte_app/core/config/app_config.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

import 'mock_database.dart';
import 'mock_exam_tasks.dart';
import 'mock_http.dart';

/// Base of the presigned upload URLs handed out by `POST /api/media/objects`.
/// `RawUploadClient`'s Dio shares the mock adapter, so the `PUT` lands on the
/// `/mock-storage/uploads` route below instead of MinIO.
const mockStorageUploadBase = 'http://mock-backend.local/mock-storage/uploads';

/// Student side: attempt lifecycle, answers, audio prompts, media uploads,
/// and the post-attempt report.
List<MockRoute> mockExamRoutes(MockDatabase db) {
  const attemptsPath = AppConfig.examAttemptsPath;
  return [
    MockRoute(
      'POST',
      attemptsPath,
      (request, params) =>
          _startOrResume(db, request.json['sessionPublicId'] as String? ?? ''),
    ),
    MockRoute(
      'GET',
      '$attemptsPath/{attemptId}/next-task',
      (request, params) => _withAttempt(db, params[0], (attempt) {
        attempt.advance();
        return MockResponse.ok(_attemptJson(attempt));
      }),
    ),
    MockRoute(
      'POST',
      '$attemptsPath/{attemptId}/submit',
      (request, params) => _withAttempt(db, params[0], (attempt) {
        attempt.complete();
        return const MockResponse.ok();
      }),
    ),
    // Always accepted — even for an unknown attempt (e.g. the dev-preview
    // screens' fake attempt ID), so SyncEngine never retries forever.
    for (final suffix in ['answers', 'answers/encrypted'])
      MockRoute('POST', '$attemptsPath/{attemptId}/$suffix', (request, params) {
        db.attempts[params[0]]?.answersReceived++;
        return const MockResponse.ok();
      }),
    MockRoute(
      'POST',
      '$attemptsPath/{attemptId}/heartbeat',
      (request, params) => const MockResponse.ok(),
    ),
    MockRoute(
      'GET',
      '$attemptsPath/{attemptId}/items/{itemId}/audio',
      (request, params) =>
          const MockResponse.ok({'audioUrl': MockExamTasks.audioPromptUrl}),
    ),
    MockRoute('POST', '/api/media/objects', (request, params) {
      final mediaPublicId = db.nextId('media');
      return MockResponse.ok({
        'mediaPublicId': mediaPublicId,
        'uploadUrl': '$mockStorageUploadBase/$mediaPublicId',
        'expiresInSeconds': 900,
      });
    }),
    MockRoute(
      'POST',
      '/api/media/objects/{mediaId}/complete',
      (request, params) => const MockResponse.ok(),
    ),
    MockRoute(
      'PUT',
      '/mock-storage/uploads/{mediaId}',
      (request, params) => const MockResponse.ok(),
    ),
    MockRoute('GET', '/api/reporting/reports/attempts/{attemptId}', (
      request,
      params,
    ) {
      final attempt = db.attempts[params[0]];
      if (attempt == null || !attempt.completed) {
        return const MockResponse.notFound('REPORT_NOT_PUBLISHED');
      }
      return MockResponse.ok(_reportJson(attempt));
    }),
  ];
}

MockResponse _startOrResume(MockDatabase db, String sessionPublicId) {
  final session = db.findById(db.sessions, sessionPublicId);
  if (session == null) return const MockResponse.notFound('SESSION_NOT_FOUND');
  if (session['status'] != 'OPEN') {
    return const MockResponse(409, message: 'SESSION_NOT_OPEN');
  }
  final inProgress = db.attempts.values
      .where((a) => a.sessionPublicId == sessionPublicId && !a.completed)
      .firstOrNull;
  if (inProgress != null) return MockResponse.ok(_attemptJson(inProgress));

  final tasks = MockExamTasks.tasksForComposition(
    session['composition'] as List<dynamic>,
  );
  if (tasks.isEmpty) {
    return const MockResponse(409, message: 'SESSION_HAS_NO_TASKS');
  }
  final attempt = MockAttempt(
    publicId: db.nextId('attempt'),
    sessionPublicId: sessionPublicId,
    tasks: tasks,
  );
  db.attempts[attempt.publicId] = attempt;
  return MockResponse.ok(_attemptJson(attempt));
}

MockResponse _withAttempt(
  MockDatabase db,
  String attemptPublicId,
  MockResponse Function(MockAttempt attempt) action,
) {
  final attempt = db.attempts[attemptPublicId];
  return attempt == null
      ? const MockResponse.notFound('ATTEMPT_NOT_FOUND')
      : action(attempt);
}

Map<String, dynamic> _attemptJson(MockAttempt attempt) => {
  'attemptPublicId': attempt.publicId,
  'attemptStatus': attempt.completed ? 'COMPLETED' : 'IN_PROGRESS',
  'completed': attempt.completed,
  'task': attempt.completed
      ? null
      : MockExamTasks.taskJson(
          attempt.currentTask,
          pinnedItemPublicId: '${attempt.publicId}-item-${attempt.cursor}',
          orderIndex: attempt.cursor,
          totalTasks: attempt.tasks.length,
        ),
  'encryptionPublicKey': null,
  // Never lockdown in mock mode — STRICT/STANDARD would hook the real
  // desktop (fullscreen, clipboard, process scans) during UI testing.
  'lockdownMode': null,
};

/// Skills for sections the attempt never covered come back as insufficient
/// data, so single-section practice sessions exercise that UI state too.
Map<String, dynamic> _reportJson(MockAttempt attempt) {
  final taskTypes = {for (final task in attempt.tasks) task.taskType};
  int? scoreIfCovered(List<TaskView> section, int score) =>
      section.any((task) => taskTypes.contains(task.taskType)) ? score : null;
  Map<String, dynamic> skill(String name, int? score) => {
    'skill': name,
    'score': score,
    'sufficientData': score != null,
  };

  final communicative = {
    'Listening': scoreIfCovered(MockExamTasks.listening, 72),
    'Reading': scoreIfCovered(MockExamTasks.reading, 68),
    'Speaking': scoreIfCovered(MockExamTasks.speaking, 61),
    'Writing': scoreIfCovered(MockExamTasks.writing, 75),
  };
  final covered = communicative.values.nonNulls.toList();
  return {
    'attemptPublicId': attempt.publicId,
    'sessionPublicId': attempt.sessionPublicId,
    'published': true,
    'publishedAt': attempt.completedAt?.toIso8601String(),
    'overall': skill(
      'Overall',
      covered.isEmpty
          ? null
          : covered.reduce((a, b) => a + b) ~/ covered.length,
    ),
    'communicativeSkills': [
      for (final entry in communicative.entries) skill(entry.key, entry.value),
    ],
    'enablingSkills': [
      skill('Grammar', 70),
      skill('Oral Fluency', scoreIfCovered(MockExamTasks.speaking, 58)),
      skill('Pronunciation', scoreIfCovered(MockExamTasks.speaking, 63)),
      skill('Spelling', scoreIfCovered(MockExamTasks.writing, 81)),
      skill('Vocabulary', 66),
      skill('Written Discourse', scoreIfCovered(MockExamTasks.writing, 74)),
    ],
  };
}
