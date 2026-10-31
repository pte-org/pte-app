import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/storage/token_store.dart';
import 'package:pte_app/features/auth/data/repositories/auth_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockTokenStore extends Mock implements TokenStore {}

String _fakeJwt() {
  String encodeSegment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final header = encodeSegment({'alg': 'RS256'});
  final payload = encodeSegment({
    'roles': ['STUDENT'],
    'tenant_id': 't1',
  });
  return '$header.$payload.sig';
}

void main() {
  late _MockApiClient apiClient;
  late _MockTokenStore tokenStore;
  late AuthRepositoryImpl repository;

  setUp(() {
    apiClient = _MockApiClient();
    tokenStore = _MockTokenStore();
    repository = AuthRepositoryImpl(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );
    when(
      () => tokenStore.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
        expiresInSeconds: any(named: 'expiresInSeconds'),
      ),
    ).thenAnswer((_) async {});
  });

  void stubLogin(Map<String, dynamic> extra) {
    when(
      () => apiClient.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        statusCode: 200,
        data: {
          'accessToken': _fakeJwt(),
          'refreshToken': 'refresh-1',
          'tokenType': 'Bearer',
          'expiresInSeconds': 900,
          ...extra,
        },
      ),
    );
  }

  void stubChangePassword() {
    when(
      () => apiClient.post<void>(
        '/api/v1/auth/change-password',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/change-password'),
        statusCode: 200,
      ),
    );
  }

  test('login reports a temporary password that must be changed', () async {
    stubLogin({'mustChangePassword': true});

    final claims = await repository.login(email: 'a', password: 'tmp');

    expect(claims.mustChangePassword, isTrue);
    expect(claims.roles, ['STUDENT']);
  });

  test('login treats a missing or false flag as no change required', () async {
    stubLogin({});
    final missing = await repository.login(email: 'a', password: 'p');
    expect(missing.mustChangePassword, isFalse);

    stubLogin({'mustChangePassword': false});
    final explicitFalse = await repository.login(email: 'a', password: 'p');
    expect(explicitFalse.mustChangePassword, isFalse);
  });

  test(
    'changePassword sends both passwords with the stored refresh token so other devices are signed out',
    () async {
      when(
        () => tokenStore.readRefreshToken(),
      ).thenAnswer((_) async => 'refresh-1');
      stubChangePassword();

      await repository.changePassword(
        currentPassword: 'tmp',
        newPassword: 'NewPassword456',
      );

      verify(
        () => apiClient.post<void>(
          '/api/v1/auth/change-password',
          data: {
            'currentPassword': 'tmp',
            'newPassword': 'NewPassword456',
            'refreshToken': 'refresh-1',
          },
        ),
      ).called(1);
    },
  );

  test('changePassword still works when no refresh token is stored', () async {
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => null);
    stubChangePassword();

    await repository.changePassword(
      currentPassword: 'tmp',
      newPassword: 'NewPassword456',
    );

    verify(
      () => apiClient.post<void>(
        '/api/v1/auth/change-password',
        data: {'currentPassword': 'tmp', 'newPassword': 'NewPassword456'},
      ),
    ).called(1);
  });
}
