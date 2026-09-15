import 'mock_database.dart';
import 'mock_http.dart';

const _sessionsPath = '/api/scheduling/sessions';

List<MockRoute> mockSchedulingRoutes(MockDatabase db) => [
  MockRoute(
    'GET',
    _sessionsPath,
    (request, params) => MockResponse.ok(db.sessions),
  ),
  MockRoute(
    'GET',
    '$_sessionsPath/{sessionId}',
    (request, params) => okOrNotFound(db.findById(db.sessions, params[0])),
  ),
  MockRoute('POST', _sessionsPath, (request, params) {
    final body = request.json;
    final session = db.newSession(
      publicId: db.nextId('session'),
      name: body['name'] as String? ?? '',
      snapshotPublicId: body['snapshotPublicId'] as String? ?? '',
      opensAt: body['opensAt'] as String,
      closesAt: body['closesAt'] as String,
    );
    db.sessions.insert(0, session);
    return MockResponse.ok(session);
  }),
  MockRoute(
    'PUT',
    '$_sessionsPath/{sessionId}/composition',
    (request, params) => _updateSession(
      db,
      params[0],
      (session) => session['composition'] = request.json['items'] ?? const [],
    ),
  ),
  MockRoute(
    'POST',
    '$_sessionsPath/{sessionId}/open',
    (request, params) =>
        _updateSession(db, params[0], (session) => session['status'] = 'OPEN'),
  ),
  MockRoute(
    'POST',
    '$_sessionsPath/{sessionId}/close',
    (request, params) => _updateSession(
      db,
      params[0],
      (session) => session['status'] = 'CLOSED',
    ),
  ),
  MockRoute('POST', '$_sessionsPath/{sessionId}/enrollments', (
    request,
    params,
  ) {
    if (db.findById(db.sessions, params[0]) == null) {
      return const MockResponse.notFound('SESSION_NOT_FOUND');
    }
    return MockResponse.ok({
      'publicId': db.nextId('enrollment'),
      'sessionPublicId': params[0],
      'studentPublicId': request.json['studentPublicId'],
    });
  }),
  MockRoute('POST', '$_sessionsPath/{sessionId}/proctors', (request, params) {
    final session = db.findById(db.sessions, params[0]);
    if (session == null) {
      return const MockResponse.notFound('SESSION_NOT_FOUND');
    }
    final assignmentPublicId = db.nextId('assignment');
    // Every mock proctor shares one "my assignments" list, so the new
    // assignment is visible after logging in as proctor@mock.local.
    db.proctorAssignments.add(db.assignmentFor(session, assignmentPublicId));
    return MockResponse.ok({
      'publicId': assignmentPublicId,
      'sessionPublicId': params[0],
      'proctorPublicId': request.json['proctorPublicId'],
    });
  }),
];

MockResponse _updateSession(
  MockDatabase db,
  String sessionPublicId,
  void Function(Map<String, dynamic> session) change,
) {
  final session = db.findById(db.sessions, sessionPublicId);
  if (session == null) return const MockResponse.notFound('SESSION_NOT_FOUND');
  change(session);
  return MockResponse.ok(session);
}
