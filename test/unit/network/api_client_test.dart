import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = _MockDio();
    apiClient = ApiClient(dio: dio);
  });

  test(
    'get unwraps a standard list envelope and preserves response metadata',
    () async {
      final requestOptions = RequestOptions(path: '/api/authoring/questions');
      final headers = Headers.fromMap({
        'content-type': ['application/json'],
      });
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: requestOptions,
          data: {
            'success': true,
            'data': <dynamic>[
              {'publicId': 'question-1'},
            ],
            'message': null,
          },
          statusCode: 200,
          statusMessage: 'OK',
          headers: headers,
          extra: const {'traceId': 'trace-1'},
        ),
      );

      final result = await apiClient.get<List<dynamic>>(
        '/api/authoring/questions',
      );

      expect(result.data, <dynamic>[
        {'publicId': 'question-1'},
      ]);
      expect(result.statusCode, 200);
      expect(result.statusMessage, 'OK');
      expect(result.headers, same(headers));
      expect(result.extra, {'traceId': 'trace-1'});
      expect(result.requestOptions, same(requestOptions));
    },
  );

  test('post unwraps a standard map envelope', () async {
    final requestOptions = RequestOptions(path: '/api/authoring/questions');
    when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {'publicId': 'question-1'},
          'message': 'Question created',
        },
      ),
    );

    final result = await apiClient.post<Map<String, dynamic>>(
      '/api/authoring/questions',
      data: {'title': 'Main idea'},
    );

    expect(result.data, {'publicId': 'question-1'});
  });

  test('post keeps an already-unwrapped payload compatible', () async {
    final requestOptions = RequestOptions(path: '/api/legacy');
    when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: requestOptions,
        data: {'publicId': 'legacy-1'},
      ),
    );

    final result = await apiClient.post<Map<String, dynamic>>('/api/legacy');

    expect(result.data, {'publicId': 'legacy-1'});
  });

  test('post supports a standard envelope whose inner data is null', () async {
    final requestOptions = RequestOptions(path: '/api/iam/auth/logout');
    when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: requestOptions,
        data: {'success': true, 'data': null, 'message': 'Logged out'},
        statusCode: 200,
      ),
    );

    final result = await apiClient.post<void>(
      '/api/iam/auth/logout',
      data: {'refreshToken': 'refresh-token'},
    );

    expect(result.statusCode, 200);
  });

  DioException errorWithStatus(
    int? statusCode, {
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    final requestOptions = RequestOptions(path: '/api/whatever');
    return DioException(
      requestOptions: requestOptions,
      type: type,
      response: statusCode == null
          ? null
          : Response(requestOptions: requestOptions, statusCode: statusCode),
    );
  }

  test('post() returns response data on success', () async {
    final response = Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/api/x'),
      data: {'ok': true},
      statusCode: 200,
    );
    when(
      () => dio.post<dynamic>(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => response);

    final result = await apiClient.post<Map<String, dynamic>>(
      '/api/x',
      data: {'a': 1},
    );

    expect(result.data, {'ok': true});
  });

  test('401 response maps to AuthException', () async {
    when(
      () => dio.post<dynamic>(any(), data: any(named: 'data')),
    ).thenThrow(errorWithStatus(401));

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<AuthException>()),
    );
  });

  test(
    '403 response maps to ForbiddenException, never AuthException',
    () async {
      when(
        () => dio.post<dynamic>(any(), data: any(named: 'data')),
      ).thenThrow(errorWithStatus(403));

      expect(
        () => apiClient.post<Map<String, dynamic>>(
          '/api/authoring/questions',
          data: {},
        ),
        throwsA(
          isA<ForbiddenException>().having(
            (error) => error,
            'not an authentication failure',
            isNot(isA<AuthException>()),
          ),
        ),
      );
    },
  );

  test('400 response maps to ValidationException', () async {
    when(
      () => dio.post<dynamic>(any(), data: any(named: 'data')),
    ).thenThrow(errorWithStatus(400));

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<ValidationException>()),
    );
  });

  test(
    '429 response maps to RateLimitException, never AuthException/ValidationException',
    () async {
      when(
        () => dio.post<dynamic>(any(), data: any(named: 'data')),
      ).thenThrow(errorWithStatus(429));

      expect(
        () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
        throwsA(isA<RateLimitException>()),
      );
    },
  );

  test('connection error (no response) maps to NetworkException', () async {
    when(
      () => dio.post<dynamic>(any(), data: any(named: 'data')),
    ).thenThrow(errorWithStatus(null, type: DioExceptionType.connectionError));

    expect(
      () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
      throwsA(isA<NetworkException>()),
    );
  });

  test(
    'unrecognized 500 maps to UnknownApiException, not silently swallowed',
    () async {
      when(
        () => dio.post<dynamic>(any(), data: any(named: 'data')),
      ).thenThrow(errorWithStatus(500));

      expect(
        () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
        throwsA(isA<UnknownApiException>()),
      );
    },
  );

  test(
    '409 response maps to ConflictException carrying the response body message',
    () async {
      final requestOptions = RequestOptions(path: '/api/x');
      when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 409,
            data: {
              'success': false,
              'data': null,
              'message': 'NOT_CURRENT_TASK',
            },
          ),
        ),
      );

      expect(
        () => apiClient.post<Map<String, dynamic>>('/api/x', data: {}),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            'NOT_CURRENT_TASK',
          ),
        ),
      );
    },
  );

  test(
    'submitAnswer() posts to the attempt answers endpoint with pinnedItemPublicId and payload',
    () async {
      final response = Response<void>(
        requestOptions: RequestOptions(path: '/api/x'),
        statusCode: 200,
      );
      when(
        () => dio.post<dynamic>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => response);

      await apiClient.submitAnswer(
        attemptPublicId: 'attempt-1',
        pinnedItemPublicId: 'item-1',
        payload: 'hello',
      );

      final captured = verify(
        () => dio.post<dynamic>(captureAny(), data: captureAny(named: 'data')),
      ).captured;
      expect(captured[0], '/api/exam-delivery/attempts/attempt-1/answers');
      expect(captured[1], {'pinnedItemPublicId': 'item-1', 'payload': 'hello'});
    },
  );

  DioException conflictWithMessage(String message) {
    final requestOptions = RequestOptions(
      path: '/api/exam-delivery/attempts/attempt-1/answers',
    );
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 409,
        data: {'success': false, 'data': null, 'message': message},
      ),
    );
  }

  group('submitAnswer() typed-409 dispatch (Step 8)', () {
    test(
      'a 409 with message "NOT_CURRENT_TASK" produces NotCurrentTaskException, not the generic ConflictException',
      () async {
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenThrow(conflictWithMessage('NOT_CURRENT_TASK'));

        await expectLater(
          () => apiClient.submitAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            payload: 'hello',
          ),
          throwsA(
            isA<NotCurrentTaskException>()
                .having((e) => e.message, 'message', 'NOT_CURRENT_TASK')
                .having(
                  (e) => e,
                  'exact runtime type',
                  isNot(isA<ResponseWindowExpiredException>()),
                ),
          ),
        );
      },
    );

    test(
      'a 409 with message "RESPONSE_WINDOW_EXPIRED" produces ResponseWindowExpiredException, not the generic ConflictException',
      () async {
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenThrow(conflictWithMessage('RESPONSE_WINDOW_EXPIRED'));

        await expectLater(
          () => apiClient.submitAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            payload: 'hello',
          ),
          throwsA(
            isA<ResponseWindowExpiredException>()
                .having((e) => e.message, 'message', 'RESPONSE_WINDOW_EXPIRED')
                .having(
                  (e) => e,
                  'exact runtime type',
                  isNot(isA<NotCurrentTaskException>()),
                ),
          ),
        );
      },
    );

    test(
      'a 409 with message "ANSWER_ALREADY_SUBMITTED" falls back to the generic ConflictException, not a crash',
      () async {
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenThrow(conflictWithMessage('ANSWER_ALREADY_SUBMITTED'));

        await expectLater(
          () => apiClient.submitAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            payload: 'hello',
          ),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.message, 'message', 'ANSWER_ALREADY_SUBMITTED')
                .having(
                  (e) => e,
                  'not a typed subclass',
                  isNot(isA<NotCurrentTaskException>()),
                )
                .having(
                  (e) => e,
                  'not a typed subclass',
                  isNot(isA<ResponseWindowExpiredException>()),
                ),
          ),
        );
      },
    );

    test(
      'a 409 with an unrecognized message falls back to the generic ConflictException, not a crash or unhandled type',
      () async {
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenThrow(conflictWithMessage('SOME_FUTURE_UNKNOWN_CODE'));

        await expectLater(
          () => apiClient.submitAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            payload: 'hello',
          ),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.message, 'message', 'SOME_FUTURE_UNKNOWN_CODE')
                .having(
                  (e) => e,
                  'not a typed subclass',
                  isNot(isA<NotCurrentTaskException>()),
                )
                .having(
                  (e) => e,
                  'not a typed subclass',
                  isNot(isA<ResponseWindowExpiredException>()),
                ),
          ),
        );
      },
    );

    test(
      'a 409 on this endpoint with no recognized message field still falls back to generic ConflictException',
      () async {
        final requestOptions = RequestOptions(
          path: '/api/exam-delivery/attempts/attempt-1/answers',
        );
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: requestOptions,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: requestOptions, statusCode: 409),
          ),
        );

        await expectLater(
          () => apiClient.submitAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            payload: 'hello',
          ),
          throwsA(isA<ConflictException>()),
        );
      },
    );
  });

  group('fetchTimerState() typed-409 dispatch (plans/phat-speaking-dynamic-prep-timing follow-up)', () {
    DioException timerConflictWithMessage(String message) {
      final requestOptions = RequestOptions(
        path: '/api/exam-delivery/attempts/attempt-1/timer',
      );
      return DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 409,
          data: {'success': false, 'data': null, 'message': message},
        ),
      );
    }

    test(
      'a 409 with message "ATTEMPT_ALREADY_COMPLETE" produces AttemptAlreadyCompleteException, not the generic '
      'ConflictException',
      () async {
        when(
          () => dio.get<dynamic>(any(), queryParameters: any(named: 'queryParameters')),
        ).thenThrow(timerConflictWithMessage('ATTEMPT_ALREADY_COMPLETE'));

        await expectLater(
          () => apiClient.fetchTimerState('attempt-1'),
          throwsA(
            isA<AttemptAlreadyCompleteException>().having(
              (e) => e.message,
              'message',
              'ATTEMPT_ALREADY_COMPLETE',
            ),
          ),
        );
      },
    );

    test(
      'fetchTimerState() calls the correct endpoint path',
      () async {
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/x'),
          data: {'phase': 'PREP'},
        );
        when(
          () => dio.get<dynamic>(any(), queryParameters: any(named: 'queryParameters')),
        ).thenAnswer((_) async => response);

        await apiClient.fetchTimerState('attempt-1');

        final captured = verify(
          () => dio.get<dynamic>(captureAny(), queryParameters: any(named: 'queryParameters')),
        ).captured;
        expect(captured.single, '/api/exam-delivery/attempts/attempt-1/timer');
      },
    );

    test(
      'a 409 with an unrecognized message falls back to the generic ConflictException, not a crash or unhandled '
      'type',
      () async {
        when(
          () => dio.get<dynamic>(any(), queryParameters: any(named: 'queryParameters')),
        ).thenThrow(timerConflictWithMessage('SOME_FUTURE_UNKNOWN_CODE'));

        await expectLater(
          () => apiClient.fetchTimerState('attempt-1'),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.message, 'message', 'SOME_FUTURE_UNKNOWN_CODE')
                .having((e) => e, 'not a typed subclass', isNot(isA<AttemptAlreadyCompleteException>())),
          ),
        );
      },
    );
  });

  group('submitEncryptedAnswer() (Phase 3)', () {
    test(
      'submitEncryptedAnswer() posts to the encrypted answers endpoint with pinnedItemPublicId, wrappedKey, iv, and ciphertext',
      () async {
        final response = Response<void>(
          requestOptions: RequestOptions(path: '/api/x'),
          statusCode: 200,
        );
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => response);

        await apiClient.submitEncryptedAnswer(
          attemptPublicId: 'attempt-1',
          pinnedItemPublicId: 'item-1',
          wrappedKey: 'wrapped-key-base64',
          iv: 'iv-base64',
          ciphertext: 'ciphertext-base64',
        );

        final captured = verify(
          () => dio.post<dynamic>(captureAny(), data: captureAny(named: 'data')),
        ).captured;
        expect(
          captured[0],
          '/api/exam-delivery/attempts/attempt-1/answers/encrypted',
        );
        expect(captured[1], {
          'pinnedItemPublicId': 'item-1',
          'wrappedKey': 'wrapped-key-base64',
          'iv': 'iv-base64',
          'ciphertext': 'ciphertext-base64',
        });
      },
    );

    test(
      'submitEncryptedAnswer() with 409 NOT_CURRENT_TASK maps to NotCurrentTaskException',
      () async {
        final requestOptions = RequestOptions(
          path: '/api/exam-delivery/attempts/attempt-1/answers/encrypted',
        );
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: requestOptions,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: requestOptions,
              statusCode: 409,
              data: {
                'success': false,
                'data': null,
                'message': 'NOT_CURRENT_TASK',
              },
            ),
          ),
        );

        await expectLater(
          () => apiClient.submitEncryptedAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            wrappedKey: 'wrapped-key',
            iv: 'iv',
            ciphertext: 'ciphertext',
          ),
          throwsA(
            isA<NotCurrentTaskException>()
                .having((e) => e.message, 'message', 'NOT_CURRENT_TASK'),
          ),
        );
      },
    );

    test(
      'submitEncryptedAnswer() with 409 RESPONSE_WINDOW_EXPIRED maps to ResponseWindowExpiredException',
      () async {
        final requestOptions = RequestOptions(
          path: '/api/exam-delivery/attempts/attempt-1/answers/encrypted',
        );
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: requestOptions,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: requestOptions,
              statusCode: 409,
              data: {
                'success': false,
                'data': null,
                'message': 'RESPONSE_WINDOW_EXPIRED',
              },
            ),
          ),
        );

        await expectLater(
          () => apiClient.submitEncryptedAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            wrappedKey: 'wrapped-key',
            iv: 'iv',
            ciphertext: 'ciphertext',
          ),
          throwsA(
            isA<ResponseWindowExpiredException>()
                .having((e) => e.message, 'message', 'RESPONSE_WINDOW_EXPIRED'),
          ),
        );
      },
    );

    test(
      'submitEncryptedAnswer() with 409 unknown message falls back to generic ConflictException',
      () async {
        final requestOptions = RequestOptions(
          path: '/api/exam-delivery/attempts/attempt-1/answers/encrypted',
        );
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: requestOptions,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: requestOptions,
              statusCode: 409,
              data: {
                'success': false,
                'data': null,
                'message': 'UNKNOWN_ERROR',
              },
            ),
          ),
        );

        await expectLater(
          () => apiClient.submitEncryptedAnswer(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            wrappedKey: 'wrapped-key',
            iv: 'iv',
            ciphertext: 'ciphertext',
          ),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.message, 'message', 'UNKNOWN_ERROR')
                .having(
                  (e) => e,
                  'not a typed subclass',
                  isNot(isA<NotCurrentTaskException>()),
                )
                .having(
                  (e) => e,
                  'not a typed subclass',
                  isNot(isA<ResponseWindowExpiredException>()),
                ),
          ),
        );
      },
    );
  });
}
