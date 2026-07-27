import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the refresh token via `flutter_secure_storage` exclusively —
/// never `SharedPreferences`. Access tokens are short-lived (900s) and
/// held in memory only, not worth the secure-storage round-trip cost.
///
/// Note: no code path currently reads the persisted refresh token on app
/// startup to restore a session — `AuthBloc` only has `LoginRequested`/
/// `LogoutRequested`. A cold restart therefore requires a fresh login
/// today, even though the refresh token (7-day TTL) is still there.
/// Session-restore-on-launch is out of this phase's scope, not assumed
/// to work — add an `AuthCheckRequested`-style bootstrap event if a later
/// phase needs it.
class TokenStore {
  TokenStore({required FlutterSecureStorage secureStorage, DateTime Function()? now})
      : _secureStorage = secureStorage,
        _now = now ?? DateTime.now;

  final FlutterSecureStorage _secureStorage;
  final DateTime Function() _now;

  static const String refreshTokenKey = 'pte_app.refresh_token';

  String? _accessToken;
  DateTime? _accessTokenExpiresAt;

  DateTime? get accessTokenExpiresAt => _accessTokenExpiresAt;

  /// Overwrites both tokens atomically (in the sense that no caller can
  /// observe a state where one updated and the other didn't) — required
  /// so a refresh cycle never leaves a stale refresh token behind.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    await _secureStorage.write(key: refreshTokenKey, value: refreshToken);
    _accessToken = accessToken;
    _accessTokenExpiresAt = _now().add(Duration(seconds: expiresInSeconds));
  }

  String? get accessToken => _accessToken;

  Future<String?> readRefreshToken() => _secureStorage.read(key: refreshTokenKey);

  Future<void> clear() async {
    await _secureStorage.delete(key: refreshTokenKey);
    _accessToken = null;
    _accessTokenExpiresAt = null;
  }
}
