import 'dart:convert';

/// Decoded request handed to every mock route handler — the adapter has
/// already drained Dio's request stream and JSON-decoded the body.
class MockRequest {
  const MockRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, String> query;
  final Object? body;

  /// The JSON object body, or an empty map for body-less/non-JSON requests
  /// (e.g. a raw audio upload).
  Map<String, dynamic> get json {
    final value = body;
    return value is Map<String, dynamic> ? value : const <String, dynamic>{};
  }
}

/// Serialized as pte-common's `ApiResponse<T>` envelope
/// (`{success, data, message}`) so `ApiClient` unwraps and error-maps it
/// exactly as it does a real gateway response.
class MockResponse {
  const MockResponse(this.statusCode, {this.data, this.message});

  const MockResponse.ok([Object? data]) : this(200, data: data);

  const MockResponse.notFound([String message = 'NOT_FOUND'])
    : this(404, message: message);

  const MockResponse.unauthorized([String message = 'INVALID_CREDENTIALS'])
    : this(401, message: message);

  final int statusCode;
  final Object? data;
  final String? message;

  String toEnvelopeJson() => jsonEncode({
    'success': statusCode < 400,
    'data': data,
    'message': message,
  });
}

MockResponse okOrNotFound(Object? data, [String message = 'NOT_FOUND']) =>
    data == null ? MockResponse.notFound(message) : MockResponse.ok(data);

typedef MockHandler =
    MockResponse Function(MockRequest request, List<String> params);

/// One `METHOD /path/{param}` entry. Each `{name}` segment matches exactly
/// one path segment and is passed to [handler] positionally.
class MockRoute {
  MockRoute(this.method, String pattern, this.handler)
    : _regex = RegExp(
        '^${pattern.replaceAll(RegExp(r'\{\w+\}'), '([^/]+)')}\$',
      );

  final String method;
  final MockHandler handler;
  final RegExp _regex;

  List<String>? match(String requestMethod, String path) {
    if (requestMethod != method) return null;
    final match = _regex.firstMatch(path);
    if (match == null) return null;
    return [for (var i = 1; i <= match.groupCount; i++) match.group(i)!];
  }
}
