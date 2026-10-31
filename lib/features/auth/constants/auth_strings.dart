/// Copy for the auth screens that sit next to sign-in. The sign-in form's own
/// strings stay in `AppStrings`; per-feature strings live here.
class AuthStrings {
  const AuthStrings._();

  /// Matches the server rule; the server stays the authority.
  static const int minPasswordLength = 8;

  static const String forgotPasswordHint =
      'Forgot your password? Contact your centre.';

  static const String changePasswordTitle = 'Choose a new password';
  static const String changePasswordSubtitle =
      'Your temporary password must be replaced before you can start an exam.';
  static const String changePasswordCurrentLabel = 'Temporary password';
  static const String changePasswordNewLabel = 'New password';
  static const String changePasswordConfirmLabel = 'Confirm new password';
  static const String changePasswordRequired = 'This field is required';
  static const String changePasswordTooShort =
      'Use at least 8 characters for the new password';
  static const String changePasswordMismatch = 'The passwords do not match';
  static const String changePasswordSubmit = 'Change password';
  static const String changePasswordFailureTitle =
      'Password could not be changed';
  static const String changePasswordSignOut = 'Sign out';
}
