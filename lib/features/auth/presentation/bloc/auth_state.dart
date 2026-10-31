import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';

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

/// Signed in with a temporary password: nothing else is reachable until it is
/// replaced. The tokens are already stored, only the change call needs them.
final class AuthPasswordChangeRequired extends AuthState {
  const AuthPasswordChangeRequired(this.claims);

  final JwtClaims claims;
}

final class AuthPasswordChanging extends AuthState {
  const AuthPasswordChanging(this.claims);

  final JwtClaims claims;
}

final class AuthPasswordChangeFailed extends AuthState {
  const AuthPasswordChangeFailed(this.claims, this.error);

  final JwtClaims claims;
  final ApiException error;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.error);

  final ApiException error;
}
