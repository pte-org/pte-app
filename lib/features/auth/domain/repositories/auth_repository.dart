import '../jwt_claims.dart';

/// Abstract interface — `AuthBloc` depends on this, never on
/// `AuthRepositoryImpl` directly (Dependency Inversion,
/// `docs/CODING_STANDARDS_APP.md`).
abstract class AuthRepository {
  Future<JwtClaims> login({required String email, required String password});

  Future<void> logout();
}
