import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/auth/domain/jwt_claims.dart';

/// Builds a syntactically-valid (but unsigned) JWT for decode testing —
/// this util never verifies the signature (that's the server's job), it
/// only reads the payload for UI branching.
String _fakeJwt(Map<String, dynamic> claims) {
  String encodeSegment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final header = encodeSegment({'alg': 'RS256', 'typ': 'JWT'});
  final payload = encodeSegment(claims);
  return '$header.$payload.fake-signature';
}

void main() {
  test('decodes roles and tenant_id from a well-formed access token', () {
    final jwt = _fakeJwt({'sub': 'user-1', 'roles': ['STUDENT'], 'tenant_id': 'tenant-1'});

    final claims = decodeJwtClaims(jwt);

    expect(claims.roles, ['STUDENT']);
    expect(claims.tenantId, 'tenant-1');
  });

  test('tenant_id is null when the claim is absent (user has no tenant)', () {
    final jwt = _fakeJwt({'sub': 'user-1', 'roles': ['PLATFORM_ADMIN']});

    final claims = decodeJwtClaims(jwt);

    expect(claims.roles, ['PLATFORM_ADMIN']);
    expect(claims.tenantId, isNull);
  });

  test('throws FormatException on a malformed token (not 3 dot-separated segments)', () {
    expect(() => decodeJwtClaims('not-a-jwt'), throwsFormatException);
  });
}
