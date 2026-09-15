import 'mock_database.dart';
import 'mock_http.dart';

/// Host-side read models: users, notification audit, proctoring, scoring
/// review.
List<MockRoute> mockMonitoringRoutes(MockDatabase db) => [
  MockRoute(
    'GET',
    '/api/iam/users',
    (request, params) => MockResponse.ok(db.users),
  ),
  MockRoute(
    'GET',
    '/api/notification/notifications',
    (request, params) => MockResponse.ok(db.notifications),
  ),
  MockRoute(
    'GET',
    '/api/proctor/exam-sessions/{sessionId}/violations',
    (request, params) =>
        MockResponse.ok(db.violationsBySession[params[0]] ?? const []),
  ),
  MockRoute(
    'POST',
    '/api/proctor/violations',
    (request, params) => const MockResponse.ok(),
  ),
  MockRoute(
    'GET',
    '/api/scheduling/proctor-assignments/me',
    (request, params) => MockResponse.ok(db.proctorAssignments),
  ),
  MockRoute('POST', '/api/scheduling/sessions/{sessionId}/score', (
    request,
    params,
  ) {
    db.pendingReviewsBySession.putIfAbsent(
      params[0],
      () => db.generateReviews(params[0], 6),
    );
    return const MockResponse.ok();
  }),
  MockRoute('GET', '/api/scoring/answers/reviews', (request, params) {
    final reviews =
        db.pendingReviewsBySession[request.query['sessionPublicId']] ??
        const <Map<String, dynamic>>[];
    final page = int.tryParse(request.query['page'] ?? '') ?? 0;
    final size = int.tryParse(request.query['size'] ?? '') ?? 20;
    return MockResponse.ok({
      'items': reviews.skip(page * size).take(size).toList(),
      'page': page,
      'size': size,
      'totalElements': reviews.length,
      'totalPages': size <= 0 ? 0 : (reviews.length / size).ceil(),
    });
  }),
  MockRoute('POST', '/api/scoring/answers/{answerId}/review', (
    request,
    params,
  ) {
    for (final reviews in db.pendingReviewsBySession.values) {
      final index = reviews.indexWhere(
        (row) => row['answerPublicId'] == params[0],
      );
      if (index >= 0) {
        return MockResponse.ok({
          ...reviews.removeAt(index),
          'status': 'HUMAN_REVIEWED',
        });
      }
    }
    return const MockResponse.notFound('ANSWER_NOT_FOUND');
  }),
  MockRoute(
    'POST',
    '/api/scheduling/sessions/{sessionId}/publish',
    (request, params) => const MockResponse.ok(),
  ),
];
