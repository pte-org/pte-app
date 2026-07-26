import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:pte_app/core/network/token_refresher.dart';
import 'package:pte_app/core/storage/token_store.dart';

class _FakeSecureStorage extends Mock implements FlutterSecureStorage {}

/// Records every call and serves canned responses so the interceptor's
/// 401 → refresh → retry flow runs through a real Dio pipeline, not a
/// hand-mocked handler.
class _FakeAdapter implements HttpClientAdapter {
  int refreshCallCount = 0;
  int protectedCallCount = 0;
  // Deliberately different from the client's stale 'expired-token' header
  // so the first request against '/protected' genuinely 401s.
  String currentValidToken = 'server-issued-token';

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/iam/auth/refresh') {
      refreshCallCount++;
      // Simulate real refresh latency so two near-simultaneous 401s both
      // land inside the single-flight window.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      currentValidToken = 'new-token';
      final body = jsonEncode({
        'accessToken': 'new-token',
        'refreshToken': 'rotated-refresh-token',
        'tokenType': 'Bearer',
        'expiresInSeconds': 900,
      });
      return ResponseBody.fromString(body, 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }

    if (options.path == '/protected') {
      protectedCallCount++;
      final authHeader = options.headers['Authorization'] as String?;
      if (authHeader == 'Bearer $currentValidToken') {
        return ResponseBody.fromString(jsonEncode({'ok': true}), 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      }
      return ResponseBody.fromString('{}', 401);
    }

    throw StateError('Unexpected path in test: ${options.path}');
  }
}

void main() {
  late _FakeAdapter adapter;
  late _FakeSecureStorage secureStorage;
  late TokenStore tokenStore;
  late Dio dio;
  late Dio refreshDio;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    adapter = _FakeAdapter();
    secureStorage = _FakeSecureStorage();
    when(() => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => secureStorage.read(key: TokenStore.refreshTokenKey)).thenAnswer((_) async => 'stale-refresh-token');
    tokenStore = TokenStore(secureStorage: secureStorage);

    refreshDio = Dio()..httpClientAdapter = adapter;
    dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(TokenRefreshInterceptor(
        refreshDio: refreshDio,
        refresher: TokenRefresher(
          refreshDio: refreshDio,
          tokenStore: tokenStore,
          refreshEndpoint: '/api/iam/auth/refresh',
        ),
      ));
  });

  test('a single 401 triggers exactly one refresh call and the retried request carries the new token', () async {
    final response = await dio.get<Map<String, dynamic>>(
      '/protected',
      options: Options(headers: {'Authorization': 'Bearer expired-token'}),
    );

    expect(response.data, {'ok': true});
    expect(adapter.refreshCallCount, 1);
    expect(adapter.protectedCallCount, 2); // original (401) + retry (200)
  });

  test('two concurrent 401s share a single in-flight refresh (single-flight)', () async {
    final results = await Future.wait([
      dio.get<Map<String, dynamic>>('/protected', options: Options(headers: {'Authorization': 'Bearer expired-token'})),
      dio.get<Map<String, dynamic>>('/protected', options: Options(headers: {'Authorization': 'Bearer expired-token'})),
    ]);

    expect(results[0].data, {'ok': true});
    expect(results[1].data, {'ok': true});
    expect(adapter.refreshCallCount, 1);
  });
}
