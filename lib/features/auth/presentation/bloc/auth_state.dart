import '../../../../core/network/api_exceptions.dart';
import '../../domain/jwt_claims.dart';

/// Separate immutable classes per `docs/CODING_STANDARDS_APP.md` — no
/// `isLoading`/`isError` boolean-flag shape. `LogoutRequested` must be
/// reachable from every one of these, not only [AuthAuthenticated]
/// (phase-01 Design Constraints).
sealed class AuthState {
  const AuthState();
}

final class AuthIdle extends AuthState {
  const AuthIdle();
}

final class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.claims);

  final JwtClaims claims;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.error);

  final ApiException error;
}
