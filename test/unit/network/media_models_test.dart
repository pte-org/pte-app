import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/cloudinary_upload_result.dart';
import 'package:pte_app/core/network/media_presign_response.dart';

void main() {
  group('MediaPresignResponse.fromJson', () {
    final json = <String, dynamic>{
      'mediaPublicId': 'm1',
      'publicId': 'pte/audio/1',
      'uploadUrl': 'https://api.cloudinary.com/v1_1/c/video/upload',
      'apiKey': 'key',
      'timestamp': '1700000000',
      'signature': 'sig',
      'folder': 'pte/audio',
      'resourceType': 'video',
      'expiresInSeconds': 900,
    };

    test('reads every field of the upload grant', () {
      final grant = MediaPresignResponse.fromJson(json);

      expect(grant.mediaPublicId, 'm1');
      expect(grant.publicId, 'pte/audio/1');
      expect(grant.uploadUrl, startsWith('https://'));
      expect(grant.apiKey, 'key');
      expect(grant.timestamp, '1700000000');
      expect(grant.signature, 'sig');
      expect(grant.folder, 'pte/audio');
      expect(grant.resourceType, 'video');
      expect(grant.expiresInSeconds, 900);
    });

    test('accepts the lifetime as a decimal number', () {
      expect(MediaPresignResponse.fromJson({...json, 'expiresInSeconds': 60.0}).expiresInSeconds, 60);
    });

    test('fails loudly when a required field is missing', () {
      final incomplete = Map<String, dynamic>.from(json)..remove('uploadUrl');

      expect(() => MediaPresignResponse.fromJson(incomplete), throwsA(isA<TypeError>()));
    });
  });

  group('CloudinaryUploadResult', () {
    final json = <String, dynamic>{
      'public_id': 'pte/audio/1',
      'asset_id': 'asset-1',
      'secure_url': 'https://res.cloudinary.com/c/video/upload/v1/a.wav',
      'resource_type': 'video',
      'format': 'wav',
      'bytes': 4096,
      'duration': 12.6,
      'version': 7,
      'signature': 'sig',
    };

    test('reads the provider response and rounds the duration to whole seconds', () {
      final result = CloudinaryUploadResult.fromJson(json);

      expect(result.publicId, 'pte/audio/1');
      expect(result.assetId, 'asset-1');
      expect(result.bytes, 4096);
      expect(result.durationSeconds, 13);
      expect(result.version, 7);
      expect(result.format, 'wav');
    });

    test('has no duration when the provider sends none', () {
      final result = CloudinaryUploadResult.fromJson(Map<String, dynamic>.from(json)..remove('duration'));

      expect(result.durationSeconds, isNull);
    });

    test('has no format when the provider sends none', () {
      final result = CloudinaryUploadResult.fromJson(Map<String, dynamic>.from(json)..remove('format'));

      expect(result.format, isNull);
    });

    test('rounds a duration of exactly half a second up', () {
      expect(CloudinaryUploadResult.fromJson({...json, 'duration': 0.5}).durationSeconds, 1);
    });

    test('toApiJson uses the API field names that the server verifies', () {
      final body = CloudinaryUploadResult.fromJson(json).toApiJson();

      expect(body, {
        'publicId': 'pte/audio/1',
        'assetId': 'asset-1',
        'secureUrl': 'https://res.cloudinary.com/c/video/upload/v1/a.wav',
        'resourceType': 'video',
        'format': 'wav',
        'bytes': 4096,
        'durationSeconds': 13,
        'version': 7,
        'signature': 'sig',
      });
    });

    test('fails loudly when the signature is missing', () {
      final incomplete = Map<String, dynamic>.from(json)..remove('signature');

      expect(() => CloudinaryUploadResult.fromJson(incomplete), throwsA(isA<TypeError>()));
    });
  });

  group('ApiException', () {
    test('toString names the concrete type and the message', () {
      expect(const AuthException('bad login').toString(), 'AuthException: bad login');
      expect(const NetworkException('offline').toString(), 'NetworkException: offline');
    });

    test('a rate limit carries the cooldown the server asked for, or null', () {
      expect(const RateLimitException('slow down', retryAfter: Duration(seconds: 5)).retryAfter,
          const Duration(seconds: 5));
      expect(const RateLimitException('slow down').retryAfter, isNull);
    });

    test('typed conflicts are conflicts, other failures are not', () {
      expect(const NotCurrentTaskException('NOT_CURRENT_TASK'), isA<ConflictException>());
      expect(const AttemptAlreadyCompleteException('DONE'), isA<ConflictException>());
      expect(const ForbiddenException('no'), isNot(isA<ConflictException>()));
      expect(const ReplayLimitExceededException('no plays'), isNot(isA<ForbiddenException>()));
    });

    test('every type can be caught as ApiException', () {
      const all = <ApiException>[
        AuthException('a'), ForbiddenException('b'), ValidationException('c'), RateLimitException('d'),
        ConflictException('e'), GoneException('f'), NotFoundException('g'), UnknownApiException('h'),
      ];

      expect(all.map((e) => e.message), ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']);
    });
  });
}
