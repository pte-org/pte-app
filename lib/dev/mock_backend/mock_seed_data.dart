/// Deterministic seed rows for the mock backend, already in the exact JSON
/// shape each pte-api endpoint returns — the app's real `fromJson` parsers
/// run against them unchanged, so a contract drift fails here too.
abstract final class MockSeedData {
  static const tenantId = 'mock-tenant';

  static List<Map<String, dynamic>> users() => [
    _user('mock-user-host', 'host@mock.local', 'Mock Host Admin', 'HOST_ADMIN'),
    _user(
      'mock-user-author',
      'author@mock.local',
      'Mock Host Author',
      'HOST_AUTHOR',
    ),
    _user('mock-user-proctor', 'proctor@mock.local', 'Mock Proctor', 'PROCTOR'),
    _user(
      'mock-user-student',
      'student@mock.local',
      'Nguyen Van An',
      'STUDENT',
    ),
    _user(
      'mock-user-student-2',
      'binh.tran@mock.local',
      'Tran Thi Binh',
      'STUDENT',
    ),
    _user(
      'mock-user-student-3',
      'cuong.le@mock.local',
      'Le Minh Cuong',
      'STUDENT',
    ),
    _user(
      'mock-user-proctor-2',
      'dung.pham@mock.local',
      'Pham Quoc Dung',
      'PROCTOR',
    ),
    _user(
      'mock-user-student-4',
      'suspended@mock.local',
      'Hoang Thu Ha',
      'STUDENT',
      status: 'SUSPENDED',
    ),
  ];

  static List<Map<String, dynamic>> questions() => [
    question(
      publicId: 'mock-q-read-aloud-1',
      taskType: 'READ_ALOUD',
      title: 'Urban transport funding',
      promptText:
          'The government announced today that funding for public transportation would increase by '
          'fifteen percent over the next fiscal year, aiming to reduce congestion in major urban centers.',
    ),
    question(
      publicId: 'mock-q-read-aloud-2',
      taskType: 'READ_ALOUD',
      visibility: 'SHARED',
      title: 'Ecosystem risk management',
      promptText:
          'The basic premise in the management of any system is the ability to minimize risk, and in an '
          'ecosystem that means protecting the integrity of the environment itself.',
    ),
    question(
      publicId: 'mock-q-mc-reading-1',
      taskType: 'MC_READING_SINGLE',
      title: 'The Endurance expedition',
      promptText:
          'In 1914 the Endurance left London for Antarctica. Within months the ship was trapped in pack '
          'ice, and the crew spent almost two years surviving on the frozen sea. Why did the expedition fail?',
      options: [
        {'text': 'The crew was lost at sea.', 'correct': false},
        {'text': 'The ship was trapped in pack ice.', 'correct': true},
        {'text': 'The crew refused to continue.', 'correct': false},
      ],
    ),
    question(
      publicId: 'mock-q-essay-1',
      taskType: 'WRITE_ESSAY',
      status: 'DRAFT',
      title: 'Remote work and productivity',
      promptText:
          'Some people believe working from home makes employees more productive. To what extent do you '
          'agree or disagree? Support your opinion with reasons and examples.',
      referenceAnswerText:
          'Remote work removes commuting time and office distractions, but it also blurs the boundary '
          'between work and rest...',
      minWordCount: 200,
      maxWordCount: 300,
    ),
  ];

  static Map<String, dynamic> question({
    required String publicId,
    required String taskType,
    required String title,
    required String promptText,
    String visibility = 'PRIVATE',
    String status = 'PUBLISHED',
    String? referenceAnswerText,
    int? minWordCount,
    int? maxWordCount,
    List<Map<String, dynamic>> options = const [],
  }) => {
    'publicId': publicId,
    'pteTaskType': taskType,
    'section': _sections[taskType] ?? 'READING',
    'visibility': visibility,
    'tenantId': visibility == 'SHARED' ? null : tenantId,
    'status': status,
    'title': title,
    'promptText': promptText,
    'audioPromptRef': null,
    'imagePromptRef': null,
    'referenceAnswerText': referenceAnswerText,
    'correctAnswerText': null,
    'minWordCount': minWordCount,
    'maxWordCount': maxWordCount,
    'options': [
      for (final (index, option) in options.indexed)
        {
          'publicId': '$publicId-option-$index',
          'text': option['text'],
          'correct': option['correct'],
          'orderIndex': index,
        },
    ],
    'skills': _skills[taskType] ?? const <String>[],
  };

  static List<Map<String, dynamic>> blueprints() => [
    _blueprint('mock-bp-foundation', 'Foundation Mock Test', 'PUBLISHED', [
      ('mock-q-read-aloud-1', 'SPEAKING'),
      ('mock-q-mc-reading-1', 'READING'),
      ('mock-q-essay-1', 'WRITING'),
    ]),
    _blueprint('mock-bp-speaking-drill', 'Speaking Drill', 'DRAFT', [
      ('mock-q-read-aloud-1', 'SPEAKING'),
      ('mock-q-read-aloud-2', 'SPEAKING'),
    ]),
  ];

  /// Mirrors authoring's publish step: freezes each blueprint item's
  /// question title/type into an immutable snapshot.
  static Map<String, dynamic> snapshot({
    required String publicId,
    required Map<String, dynamic> blueprint,
    required List<Map<String, dynamic>> questions,
    required int version,
  }) {
    final questionsById = {for (final q in questions) q['publicId']: q};
    final items = (blueprint['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return {
      'publicId': publicId,
      'name': blueprint['name'],
      'version': version,
      'sourceBlueprintPublicId': blueprint['publicId'],
      'tenantId': tenantId,
      'items': [
        for (final item in items)
          if (questionsById[item['questionPublicId']] case final question?)
            {
              'orderIndex': item['orderIndex'],
              'section': item['section'],
              'taskType': question['pteTaskType'],
              'title': question['title'],
            },
      ],
    };
  }

  static List<Map<String, dynamic>> notifications(DateTime now) => [
    _notification(
      'mock-notification-1',
      'student@mock.local',
      'SESSION_INVITATION',
      'You are invited: Full PTE Mock Exam',
      'SENT',
      now.subtract(const Duration(hours: 3)),
    ),
    _notification(
      'mock-notification-2',
      'binh.tran@mock.local',
      'SESSION_INVITATION',
      'You are invited: Speaking Practice',
      'SENT',
      now.subtract(const Duration(hours: 2)),
    ),
    _notification(
      'mock-notification-3',
      'cuong.le@mock.local',
      'RESULT_PUBLISHED',
      'Your PTE mock result is ready',
      'FAILED',
      now.subtract(const Duration(minutes: 50)),
    ),
    _notification(
      'mock-notification-4',
      'proctor@mock.local',
      'PROCTOR_ASSIGNMENT',
      'New proctoring assignment: Full PTE Mock Exam',
      'PENDING',
      null,
    ),
  ];

  static const _sections = {
    'READ_ALOUD': 'SPEAKING',
    'MC_READING_SINGLE': 'READING',
    'WRITE_ESSAY': 'WRITING',
  };

  static const _skills = {
    'READ_ALOUD': ['SPEAKING', 'READING'],
    'MC_READING_SINGLE': ['READING'],
    'WRITE_ESSAY': ['WRITING'],
  };

  static Map<String, dynamic> _user(
    String publicId,
    String email,
    String fullName,
    String role, {
    String status = 'ACTIVE',
  }) => {
    'publicId': publicId,
    'email': email,
    'fullName': fullName,
    'tenantId': tenantId,
    'status': status,
    'roles': [role],
  };

  static Map<String, dynamic> _blueprint(
    String publicId,
    String name,
    String status,
    List<(String, String)> items,
  ) => {
    'publicId': publicId,
    'name': name,
    'tenantId': tenantId,
    'status': status,
    'items': [
      for (final (index, (questionPublicId, section)) in items.indexed)
        {
          'questionPublicId': questionPublicId,
          'section': section,
          'orderIndex': index,
        },
    ],
  };

  static Map<String, dynamic> _notification(
    String publicId,
    String recipientEmail,
    String notificationType,
    String subject,
    String status,
    DateTime? sentAt,
  ) => {
    'publicId': publicId,
    'recipientEmail': recipientEmail,
    'notificationType': notificationType,
    'subject': subject,
    'status': status,
    'sentAt': sentAt?.toUtc().toIso8601String(),
  };
}
