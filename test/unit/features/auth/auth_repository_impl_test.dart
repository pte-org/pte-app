import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/storage/token_store.dart';
import 'package:pte_app/features/auth/data/repositories/auth_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockTokenStore extends Mock implements TokenStore {}

String _fakeJwt(Map<String, dynamic> claims) {
  String encodeSegment(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encodeSegment({
        'alg': 'RS256'
      })}.${encodeSegment(claims)}.sig';
}

void main() {
  late _MockApiClient apiClient;
  late _MockTokenStore tokenStore;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    apiClient = _MockApiClient();
    tokenStore = _MockTokenStore();
    repository = AuthRepositoryImpl(apiClient: apiClient, tokenStore: tokenStore);
  });

  test('login posts credentials, saves the returned tokens, and returns the decoded claims', () async {
    final accessToken = _fakeJwt({
      'roles': ['STUDENT'],
      'tenant_id': 't1',
    });
    when(() => apiClient.post<Map<String, dynamic>>('/api/iam/auth/login', data: any(named: 'data')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/iam/auth/login'),
              statusCode: 200,
              data: {
                'accessToken': accessToken,
                'refreshToken': 'refresh-1',
                'tokenType': 'Bearer',
                'expiresInSeconds': 900,
              },
            ));
    when(() => tokenStore.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          expiresInSeconds: any(named: 'expiresInSeconds'),
        )).thenAnswer((_) async {});

    final claims = await repository.login(email: 'a@b.com', password: 'secret');

    final captured = verify(() => apiClient.post<Map<String, dynamic>>(
          '/api/iam/auth/login',
          data: captureAny(named: 'data'),
        )).captured.single as Map<String, dynamic>;
    expect(captured['email'], 'a@b.com');
    expect(captured['password'], 'secret');
    verify(() => tokenStore.saveTokens(accessToken: accessToken, refreshToken: 'refresh-1', expiresInSeconds: 900))
        .called(1);
    expect(claims.roles, ['STUDENT']);
    expect(claims.tenantId, 't1');
  });

  test('logout reads the refresh token, posts it to the logout endpoint, then clears local tokens', () async {
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => 'refresh-1');
    when(() => apiClient.post<void>('/api/iam/auth/logout', data: any(named: 'data')))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/api/iam/auth/logout')));
    when(() => tokenStore.clear()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => apiClient.post<void>('/api/iam/auth/logout', data: {'refreshToken': 'refresh-1'})).called(1);
    verify(() => tokenStore.clear()).called(1);
  });

  test('logout still clears local tokens even if the server call fails (best-effort revoke)', () async {
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => 'refresh-1');
    when(() => apiClient.post<void>('/api/iam/auth/logout', data: any(named: 'data')))
        .thenThrow(Exception('network down'));
    when(() => tokenStore.clear()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => tokenStore.clear()).called(1);
  });
}
