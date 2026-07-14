import '../../domain/entities/auth_session.dart';

class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final String? role;
  final String? userType;
  final int? tenantId;
  final bool? mustChangePassword;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.role,
    required this.userType,
    required this.tenantId,
    required this.mustChangePassword,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String?,
      expiresIn: json['expiresIn'] as int?,
      role: json['role'] as String?,
      userType: json['userType'] as String?,
      tenantId: json['tenantId'] as int?,
      mustChangePassword: json['mustChangePassword'] as bool?,
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      tokenType: tokenType ?? 'Bearer',
      expiresIn: expiresIn ?? 0,
      role: role ?? '',
      userType: userType ?? '',
      tenantId: tenantId,
      mustChangePassword: mustChangePassword ?? false,
    );
  }
}
