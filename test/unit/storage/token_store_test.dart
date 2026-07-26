import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/token_store.dart';

class _FakeSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _FakeSecureStorage secureStorage;
  late TokenStore tokenStore;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    secureStorage = _FakeSecureStorage();
    when(() => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    tokenStore = TokenStore(secureStorage: secureStorage);
  });

  test('saveTokens persists refresh token via secure storage and caches access token in memory', () async {
    await tokenStore.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      expiresInSeconds: 900,
    );

    verify(() => secureStorage.write(key: TokenStore.refreshTokenKey, value: 'refresh-1')).called(1);
    expect(await tokenStore.readAccessToken(), 'access-1');
    expect(tokenStore.accessTokenExpiresAt, isNotNull);
    expect(tokenStore.accessTokenExpiresAt!.isAfter(DateTime.now()), isTrue);
  });

  test('readRefreshToken reads from secure storage, not memory', () async {
    when(() => secureStorage.read(key: TokenStore.refreshTokenKey)).thenAnswer((_) async => 'refresh-1');

    expect(await tokenStore.readRefreshToken(), 'refresh-1');
    verify(() => secureStorage.read(key: TokenStore.refreshTokenKey)).called(1);
  });

  test('clear removes the refresh token from secure storage and the cached access token', () async {
    await tokenStore.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1', expiresInSeconds: 900);

    await tokenStore.clear();

    verify(() => secureStorage.delete(key: TokenStore.refreshTokenKey)).called(1);
    expect(await tokenStore.readAccessToken(), isNull);
    expect(tokenStore.accessTokenExpiresAt, isNull);
  });

  test('saveTokens overwrites both tokens atomically on refresh — no stale refresh token survives', () async {
    await tokenStore.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1', expiresInSeconds: 900);
    await tokenStore.saveTokens(accessToken: 'access-2', refreshToken: 'refresh-2', expiresInSeconds: 900);

    verify(() => secureStorage.write(key: TokenStore.refreshTokenKey, value: 'refresh-2')).called(1);
    expect(await tokenStore.readAccessToken(), 'access-2');
  });
}
