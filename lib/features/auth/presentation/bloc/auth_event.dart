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

/// Replaces the temporary password the account signed in with.
final class PasswordChangeSubmitted extends AuthEvent {
  const PasswordChangeSubmitted({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
