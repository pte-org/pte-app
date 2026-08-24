import '../../auth/domain/jwt_claims.dart';

/// Role predicates used only to choose which Flutter workspace/actions to
/// render. The backend remains authoritative for every protected operation.
abstract final class HostAccessPolicy {
  static const String _hostAdminRole = 'HOST_ADMIN';
  static const String _hostAuthorRole = 'HOST_AUTHOR';

  static bool canEnterHostConsole(JwtClaims claims) {
    return isHostAdmin(claims) || isHostAuthor(claims);
  }

  static bool isHostAdmin(JwtClaims claims) {
    return claims.roles.contains(_hostAdminRole);
  }

  static bool isHostAuthor(JwtClaims claims) {
    return claims.roles.contains(_hostAuthorRole);
  }
}
