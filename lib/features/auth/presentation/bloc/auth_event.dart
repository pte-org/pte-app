/// Sealed per `docs/CODING_STANDARDS_APP.md` — type-safe, exhaustive
/// dispatch, no enum+dynamic-payload workaround.
sealed class AuthEvent {
  const AuthEvent();
}

final class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});

  final String email;
  final String password;
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
