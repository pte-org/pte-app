import 'mock_database.dart';
import 'mock_http.dart';
import 'mock_seed_data.dart';

const _questionsPath = '/api/authoring/questions';
const _blueprintsPath = '/api/authoring/blueprints';

List<MockRoute> mockAuthoringRoutes(MockDatabase db) => [
  MockRoute(
    'GET',
    _questionsPath,
    (request, params) => MockResponse.ok(db.questions),
  ),
  MockRoute('POST', _questionsPath, (request, params) {
    final body = request.json;
    final question = MockSeedData.question(
      publicId: db.nextId('question'),
      taskType: body['pteTaskType'] as String,
      visibility: body['visibility'] as String? ?? 'PRIVATE',
      status: 'DRAFT',
      title: body['title'] as String? ?? '',
      promptText: body['promptText'] as String? ?? '',
      referenceAnswerText: body['referenceAnswerText'] as String?,
      minWordCount: body['minWordCount'] as int?,
      maxWordCount: body['maxWordCount'] as int?,
      options: ((body['options'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>(),
    );
    db.questions.insert(0, question);
    return MockResponse.ok(question);
  }),
  MockRoute(
    'GET',
    _blueprintsPath,
    (request, params) => MockResponse.ok(db.blueprints),
  ),
  MockRoute(
    'GET',
    '$_blueprintsPath/{blueprintId}',
    (request, params) => okOrNotFound(db.findById(db.blueprints, params[0])),
  ),
  MockRoute('POST', _blueprintsPath, (request, params) {
    final blueprint = <String, dynamic>{
      'publicId': db.nextId('blueprint'),
      'name': request.json['name'],
      'tenantId': MockSeedData.tenantId,
      'status': 'DRAFT',
      'items': request.json['items'] ?? const [],
    };
    db.blueprints.insert(0, blueprint);
    return MockResponse.ok(blueprint);
  }),
  MockRoute('POST', '$_blueprintsPath/{blueprintId}/publish', (
    request,
    params,
  ) {
    final blueprint = db.findById(db.blueprints, params[0]);
    if (blueprint == null) return const MockResponse.notFound();
    return MockResponse.ok(db.publishBlueprint(blueprint));
  }),
  MockRoute(
    'GET',
    '/api/authoring/snapshots/{snapshotId}',
    (request, params) => okOrNotFound(db.snapshots[params[0]]),
  ),
];
