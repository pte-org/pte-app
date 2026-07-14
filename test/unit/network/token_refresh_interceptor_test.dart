import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aptis_app/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:aptis_app/core/network/token_store.dart';

/// Hand-written fake adapter (no mocking package added) — routes requests
/// to a per-test handler based on path, so each test can script exactly
/// what the "refresh" call and the "retried original request" return.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

class _InMemoryTokenStore implements TokenStore {
  String? _accessToken = 'expired-token';
  String? _refreshToken = 'refresh-token';

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

ResponseBody _jsonResponse(Map<String, dynamic> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('TokenRefreshInterceptor', () {
    late int refreshCallCount;
    late Dio refreshDio;
    late Dio dio;
    late _InMemoryTokenStore tokenStore;

    setUp(() {
      refreshCallCount = 0;
      tokenStore = _InMemoryTokenStore();
      refreshDio = Dio();
      dio = Dio()
        ..interceptors.add(
          TokenRefreshInterceptor(
            refreshDio: refreshDio,
            tokenStore: tokenStore,
            refreshEndpoint: '/auth/refresh',
          ),
        );
    });

    test(
      '401 then refresh succeeds: retried request returns 200 to the original caller',
      () async {
        dio.httpClientAdapter = _FakeHttpClientAdapter(
          (options) async => _jsonResponse({'error': 'unauthorized'}, 401),
        );
        refreshDio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
          if (options.path == '/auth/refresh') {
            refreshCallCount++;
            return _jsonResponse({
              'access_token': 'new-token',
              'refresh_token': 'new-refresh',
            }, 200);
          }
          return _jsonResponse({'ok': true}, 200);
        });

        final response = await dio.get<dynamic>('/answers');

        expect(response.statusCode, 200);
        expect(refreshCallCount, 1);
      },
    );

    test(
      'retried request carries the new token, not the original expired one',
      () async {
        String? capturedAuthHeader;
        dio.httpClientAdapter = _FakeHttpClientAdapter(
          (options) async => _jsonResponse({'error': 'unauthorized'}, 401),
        );
        refreshDio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
          if (options.path == '/auth/refresh') {
            return _jsonResponse({
              'access_token': 'fresh-token',
              'refresh_token': 'fresh-refresh',
            }, 200);
          }
          capturedAuthHeader = options.headers['Authorization'] as String?;
          return _jsonResponse({'ok': true}, 200);
        });

        await dio.get<dynamic>('/answers');

        expect(capturedAuthHeader, 'Bearer fresh-token');
      },
    );

    test(
      'refresh endpoint itself returns 401: original request fails, no infinite retry',
      () async {
        dio.httpClientAdapter = _FakeHttpClientAdapter(
          (options) async => _jsonResponse({'error': 'unauthorized'}, 401),
        );
        refreshDio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
          refreshCallCount++;
          return _jsonResponse({'error': 'invalid_refresh_token'}, 401);
        });

        await expectLater(
          dio.get<dynamic>('/answers'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
        expect(refreshCallCount, 1);
      },
    );

    test(
      'concurrent 401s from multiple in-flight requests trigger exactly one refresh call',
      () async {
        dio.httpClientAdapter = _FakeHttpClientAdapter(
          (options) async => _jsonResponse({'error': 'unauthorized'}, 401),
        );
        refreshDio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
          if (options.path == '/auth/refresh') {
            refreshCallCount++;
            // Simulate network latency so concurrent 401s genuinely overlap.
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return _jsonResponse({
              'access_token': 'new-token',
              'refresh_token': 'new-refresh',
            }, 200);
          }
          return _jsonResponse({'ok': true}, 200);
        });

        await Future.wait([
          dio.get<dynamic>('/answers/1'),
          dio.get<dynamic>('/answers/2'),
          dio.get<dynamic>('/answers/3'),
        ]);

        expect(refreshCallCount, 1);
      },
    );

    test(
      'non-401 responses (409, 500) pass through unmodified, refresh is never called',
      () async {
        dio.httpClientAdapter = _FakeHttpClientAdapter(
          (options) async => _jsonResponse({'error': 'conflict'}, 409),
        );
        refreshDio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
          refreshCallCount++;
          return _jsonResponse({}, 200);
        });

        await expectLater(
          dio.get<dynamic>('/answers'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'statusCode',
              409,
            ),
          ),
        );
        expect(refreshCallCount, 0);
      },
    );
  });
}
