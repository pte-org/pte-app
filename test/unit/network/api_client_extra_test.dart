import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ApiClient client;

  setUp(() {
    dio = _MockDio();
    client = ApiClient(dio: dio);
  });

  group('ApiClient extra methods and error mapping', () {
    test('put and delete execute through _run and return typed response', () async {
      final req = RequestOptions(path: '/test');
      when(
        () => dio.put<dynamic>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: req, data: {'key': 'put-val'}, statusCode: 200),
      );
      when(
        () => dio.delete<dynamic>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: req, data: {'key': 'del-val'}, statusCode: 200),
      );

      final putRes = await client.put<Map<String, dynamic>>('/test', data: {'a': 1});
      final delRes = await client.delete<Map<String, dynamic>>('/test', data: {'b': 2});

      expect(putRes.data?['key'], equals('put-val'));
      expect(delRes.data?['key'], equals('del-val'));
    });

    test('get passes custom headers through Options', () async {
      final req = RequestOptions(path: '/test-headers');
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(requestOptions: req, data: {'ok': true}, statusCode: 200),
      );

      final res = await client.get<Map<String, dynamic>>(
        '/test-headers',
        headers: {'X-Custom': 'val'},
      );
      expect(res.data?['ok'], isTrue);
    });

    test('saveAnswer remaps 409 NOT_CURRENT_TASK to NotCurrentTaskException', () async {
      final req = RequestOptions(path: '/save');
      when(
        () => dio.post<dynamic>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 409,
            data: {'message': 'NOT_CURRENT_TASK'},
          ),
        ),
      );

      await expectLater(
        client.saveAnswer(
          attemptPublicId: 'att-1',
          pinnedItemPublicId: 'pin-1',
          payload: 'answer',
        ),
        throwsA(isA<NotCurrentTaskException>()),
      );
    });

    test('saveEncryptedAnswer remaps 409 NOT_CURRENT_TASK to NotCurrentTaskException', () async {
      final req = RequestOptions(path: '/save-enc');
      when(
        () => dio.post<dynamic>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 409,
            data: {'message': 'NOT_CURRENT_TASK'},
          ),
        ),
      );

      await expectLater(
        client.saveEncryptedAnswer(
          attemptPublicId: 'att-1',
          pinnedItemPublicId: 'pin-1',
          wrappedKey: 'key',
          iv: 'iv',
          ciphertext: 'cipher',
        ),
        throwsA(isA<NotCurrentTaskException>()),
      );
    });

    test('playAudio returns audioUrl on success and remaps 403 and 410', () async {
      final req = RequestOptions(path: '/audio');
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: req,
          data: {'audioUrl': 'https://storage/prompt.mp3'},
          statusCode: 200,
        ),
      );

      final url = await client.playAudio(
        attemptPublicId: 'att-1',
        pinnedItemPublicId: 'pin-1',
        playRequestId: 'req-1',
      );
      expect(url, equals('https://storage/prompt.mp3'));

      // 403 REPLAY_LIMIT_EXCEEDED
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 403,
            data: {'message': 'REPLAY_LIMIT_EXCEEDED'},
          ),
        ),
      );

      await expectLater(
        client.playAudio(
          attemptPublicId: 'att-1',
          pinnedItemPublicId: 'pin-1',
          playRequestId: 'req-2',
        ),
        throwsA(isA<ReplayLimitExceededException>()),
      );

      // 410 AUDIO_URL_EXPIRED
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 410,
            data: {'message': 'AUDIO_URL_EXPIRED'},
          ),
        ),
      );

      await expectLater(
        client.playAudio(
          attemptPublicId: 'att-1',
          pinnedItemPublicId: 'pin-1',
          playRequestId: 'req-3',
        ),
        throwsA(isA<AudioUrlExpiredException>()),
      );
    });

    test('sendHeartbeat posts to attempt heartbeat endpoint', () async {
      final req = RequestOptions(path: '/heartbeat');
      when(
        () => dio.post<dynamic>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: req, statusCode: 200),
      );

      final res = await client.sendHeartbeat('att-heartbeat');
      expect(res.statusCode, equals(200));
    });

    test('rate limit response parses numeric retry-after header', () async {
      final req = RequestOptions(path: '/rate-limited');
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['45'],
            }),
          ),
        ),
      );

      try {
        await client.get<void>('/rate-limited');
        fail('Should throw RateLimitException');
      } on RateLimitException catch (e) {
        expect(e.retryAfter, equals(const Duration(seconds: 45)));
      }
    });
  });
}

