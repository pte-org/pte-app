import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'mock_auth_routes.dart';
import 'mock_authoring_routes.dart';
import 'mock_database.dart';
import 'mock_exam_routes.dart';
import 'mock_http.dart';
import 'mock_monitoring_routes.dart';
import 'mock_scheduling_routes.dart';

/// Dev-only stand-in for the whole pte-api gateway (plus MinIO presigned
/// uploads): answers every Dio request from an in-memory [MockDatabase]
/// instead of the network. Installed as the `httpClientAdapter` of each
/// gateway/upload `Dio` when `AppConfig.useMockBackend` is on — so
/// interceptors, `ApiClient` envelope unwrapping and error mapping, and
/// every repository's `fromJson` still run exactly as against pte-api.
class MockBackendAdapter implements HttpClientAdapter {
  MockBackendAdapter({
    MockDatabase? database,
    this.latency = const Duration(milliseconds: 350),
    Logger? logger,
  }) : database = database ?? MockDatabase.seeded(),
       _logger = logger ?? Logger() {
    _routes = [
      ...mockAuthRoutes(this.database),
      ...mockAuthoringRoutes(this.database),
      ...mockSchedulingRoutes(this.database),
      ...mockMonitoringRoutes(this.database),
      ...mockExamRoutes(this.database),
    ];
  }

  /// One instance shared by every `Dio` (gateway, token refresh, raw
  /// upload) so they all see the same state.
  static final MockBackendAdapter shared = MockBackendAdapter();

  final MockDatabase database;

  /// Simulated round-trip time, so loading states are visible in the UI.
  final Duration latency;

  final Logger _logger;
  late final List<MockRoute> _routes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bodyBytes = requestStream == null
        ? const <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final response = _dispatch(
      MockRequest(
        method: options.method.toUpperCase(),
        path: options.uri.path,
        query: options.uri.queryParameters,
        body: _decodeJson(bodyBytes),
      ),
    );
    return ResponseBody.fromString(
      response.toEnvelopeJson(),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  MockResponse _dispatch(MockRequest request) {
    for (final route in _routes) {
      final params = route.match(request.method, request.path);
      if (params == null) continue;
      try {
        return route.handler(request, params);
      } catch (error, stackTrace) {
        _logger.e(
          'Mock backend handler failed: ${request.method} ${request.path}',
          error: error,
          stackTrace: stackTrace,
        );
        return MockResponse(500, message: error.toString());
      }
    }
    _logger.w(
      'Mock backend has no route for ${request.method} ${request.path}',
    );
    return const MockResponse.notFound('MOCK_ROUTE_NOT_FOUND');
  }

  /// `null` for empty or non-JSON bodies (e.g. the raw WAV upload).
  Object? _decodeJson(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }
}
