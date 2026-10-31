import 'package:pte_app/features/auth/domain/jwt_claims.dart';

/// Abstract interface — `AuthBloc` depends on this, never on
/// `AuthRepositoryImpl` directly (Dependency Inversion,
/// `docs/CODING_STANDARDS_APP.md`).
abstract class AuthRepository {
  Future<JwtClaims> login({required String email, required String password});

  /// Replaces the signed-in account's temporary password. The stored refresh
  /// token is sent along so the server signs every other device out.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();
}
