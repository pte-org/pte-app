import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/interceptors/auth_header_interceptor.dart';
import 'package:pte_app/core/storage/token_store.dart';

class _FakeSecureStorage extends Mock implements FlutterSecureStorage {}

class _RecordingAdapter implements HttpClientAdapter {
  String? lastAuthorizationHeader;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastAuthorizationHeader = options.headers['Authorization'] as String?;
    return ResponseBody.fromString(jsonEncode({'ok': true}), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

void main() {
  setUpAll(() => registerFallbackValue(''));

  test('attaches the current access token as a Bearer header on every request', () async {
    final secureStorage = _FakeSecureStorage();
    when(() => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    final tokenStore = TokenStore(secureStorage: secureStorage);
    await tokenStore.saveTokens(accessToken: 'live-token', refreshToken: 'r', expiresInSeconds: 900);

    final adapter = _RecordingAdapter();
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthHeaderInterceptor(tokenStore: tokenStore));

    await dio.get<Map<String, dynamic>>('/protected');

    expect(adapter.lastAuthorizationHeader, 'Bearer live-token');
  });

  test('sends no Authorization header when no access token is stored yet (e.g. pre-login)', () async {
    final secureStorage = _FakeSecureStorage();
    final tokenStore = TokenStore(secureStorage: secureStorage);

    final adapter = _RecordingAdapter();
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthHeaderInterceptor(tokenStore: tokenStore));

    await dio.get<Map<String, dynamic>>('/public');

    expect(adapter.lastAuthorizationHeader, isNull);
  });
}
