class AuthSession {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final String role;
  final String userType;
  final int? tenantId;
  final bool mustChangePassword;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.role,
    required this.userType,
    required this.tenantId,
    required this.mustChangePassword,
  });

  bool get isStudent => userType == 'STUDENT';
}
