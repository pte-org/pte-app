import 'dart:convert';

/// UI-branching-only claims decoded from the access token's payload
/// (student vs host layout). **Never used for an authorization decision**
/// — the signature is never verified here; the server re-validates every
/// request regardless of what the client believes its own role is
/// (phase-01 Design Constraints, FR-02).
class JwtClaims {
  const JwtClaims({required this.roles, this.tenantId});

  final List<String> roles;
  final String? tenantId;
}

/// Manual base64Url decode of the JWT payload segment — no `jwt_decoder`
/// dependency, per spec.md's Assumptions (KISS/YAGNI: this app never
/// needs to verify a signature, only read two UI-branching fields).
JwtClaims decodeJwtClaims(String jwt) {
  final segments = jwt.split('.');
  if (segments.length != 3) {
    throw const FormatException('Not a well-formed JWT (expected 3 dot-separated segments)');
  }

  final payloadSegment = base64Url.normalize(segments[1]);
  final payloadJson = utf8.decode(base64Url.decode(payloadSegment));
  final claims = jsonDecode(payloadJson) as Map<String, dynamic>;

  final roles = (claims['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
  final tenantId = claims['tenant_id'] as String?;

  return JwtClaims(roles: roles, tenantId: tenantId);
}
