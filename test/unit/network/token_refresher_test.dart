import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/token_refresher.dart';
import 'package:pte_app/core/storage/token_store.dart';

class _FakeSecureStorage extends Mock implements FlutterSecureStorage {}

class _CountingAdapter implements HttpClientAdapter {
  int callCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, requestStream, cancelFuture) async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final body = jsonEncode({
      'accessToken': 'new-token-$callCount',
      'refreshToken': 'rotated-refresh-$callCount',
      'tokenType': 'Bearer',
      'expiresInSeconds': 900,
    });
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

void main() {
  setUpAll(() => registerFallbackValue(''));

  test('two concurrent refresh() calls share a single in-flight request', () async {
    final adapter = _CountingAdapter();
    final refreshDio = Dio()..httpClientAdapter = adapter;
    final secureStorage = _FakeSecureStorage();
    when(() => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => secureStorage.read(key: TokenStore.refreshTokenKey)).thenAnswer((_) async => 'stale');
    final tokenStore = TokenStore(secureStorage: secureStorage);

    final refresher = TokenRefresher(
      refreshDio: refreshDio,
      tokenStore: tokenStore,
      refreshEndpoint: '/api/iam/auth/refresh',
    );

    final results = await Future.wait([refresher.refresh(), refresher.refresh()]);

    expect(adapter.callCount, 1);
    expect(results[0], results[1]);
    expect(tokenStore.accessToken, results[0]);
  });

  test('a later refresh() call after the first completes issues a new request (not stuck single-flight forever)', () async {
    final adapter = _CountingAdapter();
    final refreshDio = Dio()..httpClientAdapter = adapter;
    final secureStorage = _FakeSecureStorage();
    when(() => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => secureStorage.read(key: TokenStore.refreshTokenKey)).thenAnswer((_) async => 'stale');
    final tokenStore = TokenStore(secureStorage: secureStorage);
    final refresher = TokenRefresher(refreshDio: refreshDio, tokenStore: tokenStore, refreshEndpoint: '/api/iam/auth/refresh');

    await refresher.refresh();
    await refresher.refresh();

    expect(adapter.callCount, 2);
  });
}
