import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/storage/token_store.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required ApiClient apiClient, required TokenStore tokenStore})
      : _apiClient = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  @override
  Future<JwtClaims> login({required String email, required String password}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/iam/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    final accessToken = data['accessToken'] as String;
    await _tokenStore.saveTokens(
      accessToken: accessToken,
      refreshToken: data['refreshToken'] as String,
      expiresInSeconds: data['expiresInSeconds'] as int,
    );
    return decodeJwtClaims(accessToken);
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _apiClient.post<void>('/api/iam/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Best-effort server-side revoke — local state must still clear
      // even if the server is unreachable; the refresh token still gets
      // invalidated server-side on its own eventual expiry (7d TTL).
    } finally {
      await _tokenStore.clear();
    }
  }
}
