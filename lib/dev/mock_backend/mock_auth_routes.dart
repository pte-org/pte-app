import 'dart:convert';

import 'mock_database.dart';
import 'mock_http.dart';

const _accessTokenTtl = Duration(hours: 12);

/// Any seeded ACTIVE user's email logs in with any non-empty password; the
/// role comes from the seeded user row (see `MockSeedData.users`).
List<MockRoute> mockAuthRoutes(MockDatabase db) => [
  MockRoute('POST', '/api/iam/auth/login', (request, params) {
    final email = (request.json['email'] as String? ?? '').trim().toLowerCase();
    final password = request.json['password'] as String? ?? '';
    final user = db.users
        .where((row) => row['email'] == email && row['status'] == 'ACTIVE')
        .firstOrNull;
    if (user == null || password.isEmpty) {
      return const MockResponse.unauthorized();
    }
    return MockResponse.ok(_tokenPair(user));
  }),
  MockRoute('POST', '/api/iam/auth/refresh', (request, params) {
    final refreshToken = request.json['refreshToken'];
    final user = db.users
        .where((row) => _refreshTokenFor(row) == refreshToken)
        .firstOrNull;
    return user == null
        ? const MockResponse.unauthorized('INVALID_REFRESH_TOKEN')
        : MockResponse.ok(_tokenPair(user));
  }),
  MockRoute(
    'POST',
    '/api/iam/auth/logout',
    (request, params) => const MockResponse.ok(),
  ),
];

Map<String, dynamic> _tokenPair(Map<String, dynamic> user) => {
  'accessToken': _unsignedJwt({
    'sub': user['publicId'],
    'email': user['email'],
    'roles': user['roles'],
    'tenant_id': user['tenantId'],
    'exp': DateTime.now().add(_accessTokenTtl).millisecondsSinceEpoch ~/ 1000,
  }),
  'refreshToken': _refreshTokenFor(user),
  'expiresInSeconds': _accessTokenTtl.inSeconds,
};

String _refreshTokenFor(Map<String, dynamic> user) =>
    'mock-refresh-${user['publicId']}';

/// `alg: none` token — the app only base64-decodes the payload for UI
/// branching and never verifies a signature (see `decodeJwtClaims`).
String _unsignedJwt(Map<String, dynamic> claims) {
  String segment(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${segment({'alg': 'none', 'typ': 'JWT'})}.${segment(claims)}.mock';
}
