import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pte_app/core/network/interceptors/auth_header_interceptor.dart';
import 'package:pte_app/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:pte_app/core/network/raw_upload_client.dart';

/// Records the outgoing request's headers (so the test can assert directly
/// on the absence of `Authorization`, not merely infer it from a successful
/// response) and returns a canned status code so tests can simulate MinIO's
/// expired/invalid-presigned-URL error shapes without any real network call.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.statusCode);

  final int statusCode;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    // Drain the request stream so the call completes deterministically.
    if (requestStream != null) {
      await requestStream.toList();
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': statusCode < 300}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Future<File> _tempFile(String contents) async {
  final dir = await Directory.systemTemp.createTemp('raw_upload_client_test');
  final file = File(p.join(dir.path, 'recording.wav'));
  await file.writeAsString(contents);
  return file;
}

void main() {
  group('RawUploadClient — no-auth-header requirement (Step 9)', () {
    test(
      'interceptors never includes an auth-related interceptor by default — a plain Dio() may carry Dio\'s own '
      'internal ImplyContentTypeInterceptor, but never AuthHeaderInterceptor/TokenRefreshInterceptor',
      () {
        final client = RawUploadClient();

        expect(client.interceptors.whereType<AuthHeaderInterceptor>(), isEmpty);
        expect(client.interceptors.whereType<TokenRefreshInterceptor>(), isEmpty);
      },
    );

    test('a Dio instance handed in is never given an auth interceptor via the client either', () {
      final dio = Dio();
      final client = RawUploadClient(dio: dio);

      expect(client.interceptors.whereType<AuthHeaderInterceptor>(), isEmpty);
      expect(client.interceptors.whereType<TokenRefreshInterceptor>(), isEmpty);
    });

    test('putFile never attaches an Authorization header on the outgoing PUT request', () async {
      final adapter = _RecordingAdapter(200);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = RawUploadClient(dio: dio);
      final file = await _tempFile('fake audio bytes');
      addTearDown(() async {
        if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
      });

      await client.putFile('https://minio.example.com/bucket/object?sig=abc', file, contentType: 'audio/wav');

      expect(adapter.lastRequest, isNotNull);
      expect(adapter.lastRequest!.headers.containsKey('Authorization'), isFalse);
      expect(adapter.lastRequest!.headers.containsKey(Headers.wwwAuthenticateHeader), isFalse);
    });
  });

  group('RawUploadClient — expired/invalid presigned URL detection (Step 10)', () {
    test('a 403 response throws RawUploadException with looksExpired = true', () async {
      final adapter = _RecordingAdapter(403);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = RawUploadClient(dio: dio);
      final file = await _tempFile('fake audio bytes');
      addTearDown(() async {
        if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
      });

      await expectLater(
        client.putFile('https://minio.example.com/bucket/object?sig=stale', file, contentType: 'audio/wav'),
        throwsA(isA<RawUploadException>().having((e) => e.looksExpired, 'looksExpired', isTrue)),
      );
    });

    test('a 400 response throws RawUploadException with looksExpired = true', () async {
      final adapter = _RecordingAdapter(400);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = RawUploadClient(dio: dio);
      final file = await _tempFile('fake audio bytes');
      addTearDown(() async {
        if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
      });

      await expectLater(
        client.putFile('https://minio.example.com/bucket/object?sig=stale', file, contentType: 'audio/wav'),
        throwsA(isA<RawUploadException>().having((e) => e.looksExpired, 'looksExpired', isTrue)),
      );
    });

    test('a 500 response throws RawUploadException with looksExpired = false (a generic failure, not an expiry signal)', () async {
      final adapter = _RecordingAdapter(500);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = RawUploadClient(dio: dio);
      final file = await _tempFile('fake audio bytes');
      addTearDown(() async {
        if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
      });

      await expectLater(
        client.putFile('https://minio.example.com/bucket/object?sig=whatever', file, contentType: 'audio/wav'),
        throwsA(isA<RawUploadException>().having((e) => e.looksExpired, 'looksExpired', isFalse)),
      );
    });

    test('a successful 200 response resolves normally without throwing', () async {
      final adapter = _RecordingAdapter(200);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = RawUploadClient(dio: dio);
      final file = await _tempFile('fake audio bytes');
      addTearDown(() async {
        if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
      });

      await expectLater(
        client.putFile('https://minio.example.com/bucket/object?sig=fresh', file, contentType: 'audio/wav'),
        completes,
      );
    });
  });
}
