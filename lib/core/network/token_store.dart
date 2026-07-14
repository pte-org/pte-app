/// Hook point for persisting auth tokens. Phase 3 only needs the
/// interface so the refresh interceptor has something to call — wiring
/// a real secure-storage-backed implementation is a later concern and
/// does not change this contract.
abstract class TokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
}

/// Default in-memory implementation. Tokens are lost on app restart —
/// acceptable as a Phase 3 placeholder, not acceptable for production
/// (swap for a secure-storage-backed [TokenStore] before shipping).
class InMemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
}
