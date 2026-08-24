import '../../auth/domain/jwt_claims.dart';

abstract final class LiveProctorAccessPolicy {
  static bool canControl(JwtClaims claims) => claims.roles.contains('PROCTOR');

  static bool canObserve(JwtClaims claims) =>
      claims.roles.contains('HOST_ADMIN');
}
