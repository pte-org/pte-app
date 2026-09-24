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
/// response) and returns a canned status code so tests can simulate
/// Cloudinary's signed-upload error shapes without any real network call.
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
      jsonEncode(
        statusCode < 300
            ? {
                'public_id': 'pte/submissions/test',
                'asset_id': 'asset-1',
                'secure_url':
                    'https://res.cloudinary.com/test/video/upload/v1/test.wav',
                'resource_type': 'video',
                'format': 'wav',
                'bytes': 16,
                'duration': 1.0,
                'version': 1,
                'signature': 'provider-signature',
              }
            : {
                'error': {'message': 'upload failed'},
              },
      ),
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
        expect(
          client.interceptors.whereType<TokenRefreshInterceptor>(),
          isEmpty,
        );
      },
    );

    test(
      'a Dio instance handed in is never given an auth interceptor via the client either',
      () {
        final dio = Dio();
        final client = RawUploadClient(dio: dio);

        expect(client.interceptors.whereType<AuthHeaderInterceptor>(), isEmpty);
        expect(
          client.interceptors.whereType<TokenRefreshInterceptor>(),
          isEmpty,
        );
      },
    );

    test(
      'upload never attaches an Authorization header on the outgoing request',
      () async {
        final adapter = _RecordingAdapter(200);
        final dio = Dio()..httpClientAdapter = adapter;
        final client = RawUploadClient(dio: dio);
        final file = await _tempFile('fake audio bytes');
        addTearDown(() async {
          if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
        });

        await client.upload(
          uploadUrl:
              'https://api.cloudinary.com/test/video/authenticated/upload',
          file: file,
          contentType: 'audio/wav',
          apiKey: 'test-key',
          timestamp: '1700000000',
          signature: 'test-signature',
          folder: 'pte/submissions',
          publicId: 'test',
        );

        expect(adapter.lastRequest, isNotNull);
        expect(
          adapter.lastRequest!.headers.containsKey('Authorization'),
          isFalse,
        );
        expect(
          adapter.lastRequest!.headers.containsKey(
            Headers.wwwAuthenticateHeader,
          ),
          isFalse,
        );
        expect(
          adapter.lastRequest!.uri.path,
          endsWith('/video/authenticated/upload'),
        );
        final uploadForm = adapter.lastRequest!.data as FormData;
        expect(uploadForm.fields.any((field) => field.key == 'type'), isFalse);
      },
    );
  });

  group(
    'RawUploadClient — expired/invalid presigned URL detection (Step 10)',
    () {
      test(
        'a 403 response throws RawUploadException with looksExpired = true',
        () async {
          final adapter = _RecordingAdapter(403);
          final dio = Dio()..httpClientAdapter = adapter;
          final client = RawUploadClient(dio: dio);
          final file = await _tempFile('fake audio bytes');
          addTearDown(() async {
            if (file.parent.existsSync()) {
              file.parent.deleteSync(recursive: true);
            }
          });

          await expectLater(
            client.upload(
              uploadUrl: 'https://api.cloudinary.com/test/video/upload',
              file: file,
              contentType: 'audio/wav',
              apiKey: 'test-key',
              timestamp: '1700000000',
              signature: 'stale',
              folder: 'pte/submissions',
              publicId: 'test',
            ),
            throwsA(
              isA<RawUploadException>().having(
                (e) => e.looksExpired,
                'looksExpired',
                isTrue,
              ),
            ),
          );
        },
      );

      test(
        'a 400 response throws RawUploadException with looksExpired = true',
        () async {
          final adapter = _RecordingAdapter(400);
          final dio = Dio()..httpClientAdapter = adapter;
          final client = RawUploadClient(dio: dio);
          final file = await _tempFile('fake audio bytes');
          addTearDown(() async {
            if (file.parent.existsSync()) {
              file.parent.deleteSync(recursive: true);
            }
          });

          await expectLater(
            client.upload(
              uploadUrl: 'https://api.cloudinary.com/test/video/upload',
              file: file,
              contentType: 'audio/wav',
              apiKey: 'test-key',
              timestamp: '1700000000',
              signature: 'stale',
              folder: 'pte/submissions',
              publicId: 'test',
            ),
            throwsA(
              isA<RawUploadException>().having(
                (e) => e.looksExpired,
                'looksExpired',
                isTrue,
              ),
            ),
          );
        },
      );

      test(
        'a 500 response throws RawUploadException with looksExpired = false (a generic failure, not an expiry signal)',
        () async {
          final adapter = _RecordingAdapter(500);
          final dio = Dio()..httpClientAdapter = adapter;
          final client = RawUploadClient(dio: dio);
          final file = await _tempFile('fake audio bytes');
          addTearDown(() async {
            if (file.parent.existsSync()) {
              file.parent.deleteSync(recursive: true);
            }
          });

          await expectLater(
            client.upload(
              uploadUrl: 'https://api.cloudinary.com/test/video/upload',
              file: file,
              contentType: 'audio/wav',
              apiKey: 'test-key',
              timestamp: '1700000000',
              signature: 'whatever',
              folder: 'pte/submissions',
              publicId: 'test',
            ),
            throwsA(
              isA<RawUploadException>().having(
                (e) => e.looksExpired,
                'looksExpired',
                isFalse,
              ),
            ),
          );
        },
      );

      test(
        'a successful 200 response resolves normally without throwing',
        () async {
          final adapter = _RecordingAdapter(200);
          final dio = Dio()..httpClientAdapter = adapter;
          final client = RawUploadClient(dio: dio);
          final file = await _tempFile('fake audio bytes');
          addTearDown(() async {
            if (file.parent.existsSync()) {
              file.parent.deleteSync(recursive: true);
            }
          });

          await expectLater(
            client.upload(
              uploadUrl: 'https://api.cloudinary.com/test/video/upload',
              file: file,
              contentType: 'audio/wav',
              apiKey: 'test-key',
              timestamp: '1700000000',
              signature: 'fresh',
              folder: 'pte/submissions',
              publicId: 'test',
            ),
            completes,
          );
        },
      );
    },
  );
}
