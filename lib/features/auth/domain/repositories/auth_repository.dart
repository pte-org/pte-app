import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String credential,
    required String password,
  });
}
