import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

import 'mock_exam_tasks.dart';
import 'mock_seed_data.dart';

/// One mock exam attempt. The cursor only moves on `next-task`/`submit`,
/// matching how `ExamAttemptBloc` drives the real attempt lifecycle.
class MockAttempt {
  MockAttempt({
    required this.publicId,
    required this.sessionPublicId,
    required this.tasks,
  });

  final String publicId;
  final String sessionPublicId;
  final List<TaskView> tasks;
  int cursor = 0;
  int answersReceived = 0;
  DateTime? completedAt;

  bool get completed => completedAt != null;

  TaskView get currentTask => tasks[cursor];

  void advance() {
    if (completed) return;
    cursor++;
    if (cursor >= tasks.length) complete();
  }

  void complete() => completedAt ??= DateTime.now().toUtc();
}

/// Mutable in-memory state behind `MockBackendAdapter`. Lives for the app
/// process only — every cold start re-seeds, so create/open/approve/publish
/// flows can be replayed freely.
class MockDatabase {
  MockDatabase.seeded({DateTime? now})
    : _now = (now ?? DateTime.now()).toUtc() {
    users.addAll(MockSeedData.users());
    questions.addAll(MockSeedData.questions());
    blueprints.addAll(MockSeedData.blueprints());
    snapshots[foundationSnapshotId] = MockSeedData.snapshot(
      publicId: foundationSnapshotId,
      blueprint: findById(blueprints, 'mock-bp-foundation')!,
      questions: questions,
      version: 1,
    );
    notifications.addAll(MockSeedData.notifications(_now));
    _seedSessions();
    _seedMonitoring();
  }

  static const foundationSnapshotId = 'mock-snapshot-foundation';

  static const _sessionNames = {
    MockExamTasks.fullExamSessionId: 'Full PTE Mock Exam',
    'mock-speaking': 'Speaking Practice',
    'mock-writing': 'Writing Practice',
    'mock-reading': 'Reading Practice',
    'mock-listening': 'Listening Practice',
  };

  static const _reviewTaskTypes = [
    'READ_ALOUD',
    'WRITE_ESSAY',
    'DESCRIBE_IMAGE',
    'SUMMARIZE_WRITTEN_TEXT',
    'RE_TELL_LECTURE',
  ];

  final DateTime _now;

  /// Makes runtime-created IDs unique per app launch, so rows the local
  /// Drift outbox kept from a previous run never collide with new attempts.
  final String _runId = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  int _idCounter = 0;

  final users = <Map<String, dynamic>>[];
  final questions = <Map<String, dynamic>>[];
  final blueprints = <Map<String, dynamic>>[];
  final snapshots = <String, Map<String, dynamic>>{};
  final sessions = <Map<String, dynamic>>[];
  final notifications = <Map<String, dynamic>>[];
  final proctorAssignments = <Map<String, dynamic>>[];
  final violationsBySession = <String, List<Map<String, dynamic>>>{};
  final pendingReviewsBySession = <String, List<Map<String, dynamic>>>{};
  final attempts = <String, MockAttempt>{};

  String nextId(String kind) => 'mock-$kind-$_runId-${++_idCounter}';

  Map<String, dynamic>? findById(
    List<Map<String, dynamic>> rows,
    String publicId,
  ) => rows.where((row) => row['publicId'] == publicId).firstOrNull;

  Map<String, dynamic> publishBlueprint(Map<String, dynamic> blueprint) {
    final version =
        snapshots.values
            .where((s) => s['sourceBlueprintPublicId'] == blueprint['publicId'])
            .length +
        1;
    final snapshot = MockSeedData.snapshot(
      publicId: nextId('snapshot'),
      blueprint: blueprint,
      questions: questions,
      version: version,
    );
    snapshots[snapshot['publicId'] as String] = snapshot;
    blueprint['status'] = 'PUBLISHED';
    return snapshot;
  }

  Map<String, dynamic> newSession({
    required String publicId,
    required String name,
    required String opensAt,
    required String closesAt,
    String snapshotPublicId = foundationSnapshotId,
    String status = 'SCHEDULED',
    List<Map<String, dynamic>> composition = const [],
  }) => {
    'publicId': publicId,
    'name': name,
    'tenantId': MockSeedData.tenantId,
    'snapshotPublicId': snapshotPublicId,
    'opensAt': opensAt,
    'closesAt': closesAt,
    'status': status,
    'composition': [...composition],
  };

  Map<String, dynamic> assignmentFor(
    Map<String, dynamic> session,
    String assignmentPublicId,
  ) => {
    'assignmentPublicId': assignmentPublicId,
    'sessionPublicId': session['publicId'],
    'name': session['name'],
    'opensAt': session['opensAt'],
    'closesAt': session['closesAt'],
    'status': session['status'],
  };

  List<Map<String, dynamic>> generateReviews(
    String sessionPublicId,
    int count,
  ) => [
    for (var i = 1; i <= count; i++)
      {
        'answerPublicId': 'mock-answer-$sessionPublicId-$i',
        'attemptPublicId': 'mock-attempt-demo-${i % 4 + 1}',
        'taskType': _reviewTaskTypes[i % _reviewTaskTypes.length],
        'status': 'AI_SCORED_PENDING_REVIEW',
        'rawScore': i % 6 == 0 ? null : 35 + (i * 7) % 55,
      },
  ];

  String _at(Duration offset) => _now.add(offset).toIso8601String();

  void _seedSessions() {
    MockExamTasks.sessionTaskSets.forEach((publicId, tasks) {
      sessions.add(
        newSession(
          publicId: publicId,
          name: _sessionNames[publicId] ?? publicId,
          status: 'OPEN',
          opensAt: _at(const Duration(hours: -1)),
          closesAt: _at(const Duration(days: 7)),
          composition: [
            for (final (index, task) in tasks.indexed)
              {
                'taskType': task.taskType,
                'section': task.section,
                'orderIndex': index,
                'timingOverrideSeconds': null,
              },
          ],
        ),
      );
    });
    sessions
      ..add(
        newSession(
          publicId: 'mock-scheduled-next-week',
          name: 'Scheduled Mock Test (next week)',
          opensAt: _at(const Duration(days: 7)),
          closesAt: _at(const Duration(days: 7, hours: 3)),
          composition: [
            {
              'taskType': 'READ_ALOUD',
              'section': 'SPEAKING',
              'orderIndex': 0,
              'timingOverrideSeconds': null,
            },
          ],
        ),
      )
      ..add(
        newSession(
          publicId: 'mock-closed-last-month',
          name: 'Closed Mock Test (last month)',
          status: 'CLOSED',
          opensAt: _at(const Duration(days: -30)),
          closesAt: _at(const Duration(days: -30, hours: 3)),
        ),
      );
  }

  void _seedMonitoring() {
    const fullExam = MockExamTasks.fullExamSessionId;
    violationsBySession[fullExam] = [
      _violation(
        1,
        'mock-attempt-demo-1',
        'TAB_SWITCH',
        'Exam window lost focus for 4 seconds',
        -42,
      ),
      _violation(
        2,
        'mock-attempt-demo-2',
        'MULTIPLE_FACES',
        'Two faces detected in webcam frame',
        -27,
      ),
      _violation(
        3,
        'mock-attempt-demo-1',
        'SUSPICIOUS_AUDIO',
        'Background voice detected during Read Aloud',
        -11,
      ),
      _violation(
        4,
        'mock-attempt-demo-3',
        'TECHNICAL_ISSUE',
        'Microphone disconnected and reconnected',
        -5,
      ),
    ];
    for (final sessionPublicId in [fullExam, 'mock-speaking']) {
      proctorAssignments.add(
        assignmentFor(
          findById(sessions, sessionPublicId)!,
          'mock-assignment-$sessionPublicId',
        ),
      );
    }
    pendingReviewsBySession[fullExam] = generateReviews(fullExam, 25);
    pendingReviewsBySession['mock-closed-last-month'] = generateReviews(
      'mock-closed-last-month',
      3,
    );
  }

  Map<String, dynamic> _violation(
    int sequenceNo,
    String attemptPublicId,
    String violationType,
    String detail,
    int minutesAgo,
  ) => {
    'publicId': 'mock-violation-$sequenceNo',
    'attemptPublicId': attemptPublicId,
    'violationType': violationType,
    'detail': detail,
    'sequenceNo': sequenceNo,
    'hash': 'sha256:mock${sequenceNo.toString().padLeft(4, '0')}',
    'detectedAt': _at(Duration(minutes: minutesAgo)),
  };
}
