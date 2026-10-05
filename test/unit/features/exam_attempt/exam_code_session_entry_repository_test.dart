import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/config/app_config.dart';
import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/exam_code_session_entry_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';

class _MockApiClient extends Mock implements ApiClient {}

const _sessionUuid = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const _canonicalCode = 'FPT-261010-K7QM';

void main() {
  late _MockApiClient apiClient;
  late ExamCodeSessionEntryRepository repository;

  Future<Response<Map<String, dynamic>>> resolveCall() =>
      apiClient.get<Map<String, dynamic>>(
        AppConfig.sessionCodeResolvePath,
        queryParameters: any(named: 'queryParameters'),
      );

  Map<String, dynamic> capturedQuery() =>
      verify(
            () => apiClient.get<Map<String, dynamic>>(
              AppConfig.sessionCodeResolvePath,
              queryParameters: captureAny(named: 'queryParameters'),
            ),
          ).captured.single
          as Map<String, dynamic>;

  setUp(() {
    apiClient = _MockApiClient();
    repository = ExamCodeSessionEntryRepository(apiClient: apiClient);
    when(resolveCall).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: AppConfig.sessionCodeResolvePath),
        statusCode: 200,
        data: {'sessionPublicId': _sessionUuid},
      ),
    );
  });

  group('UUID passthrough', () {
    for (final input in [
      _sessionUuid,
      '  3F2504E0-4F89-41D3-9A0C-0305E82C3301  ',
    ]) {
      test('"$input" is returned trimmed without calling the API', () async {
        expect(await repository.resolveSessionPublicId(input), input.trim());
        verifyZeroInteractions(apiClient);
      });
    }

    test('a UUID without hyphens is not treated as a UUID', () async {
      await repository.resolveSessionPublicId(
        '3f2504e04f8941d39a0c0305e82c3301',
      );

      expect(capturedQuery(), {'code': '3F2504E04F8941D39A0C0305E82C3301'});
    });
  });

  group('exam code normalization', () {
    for (final input in [
      '  fpt-261010-k7qm ',
      'FPT – 261010 – K7QM',
      'fpt—261010—k7qm',
    ]) {
      test('"$input" resolves once with $_canonicalCode', () async {
        expect(await repository.resolveSessionPublicId(input), _sessionUuid);
        expect(capturedQuery(), {'code': _canonicalCode});
      });
    }
  });

  group('input the student cannot use', () {
    for (final input in ['', '   ']) {
      test('"$input" throws without calling the API', () async {
        await expectLater(
          repository.resolveSessionPublicId(input),
          throwsA(isA<SessionResolutionException>()),
        );
        verifyZeroInteractions(apiClient);
      });
    }

    test('an unknown code (404) becomes a friendly SessionResolutionException', () async {
      when(resolveCall).thenThrow(const NotFoundException('SESSION_NOT_FOUND'));

      await expectLater(
        repository.resolveSessionPublicId(_canonicalCode),
        throwsA(
          isA<SessionResolutionException>().having(
            (e) => e.message,
            'message',
            "We couldn't find that exam code. Check the code from your host and try again.",
          ),
        ),
      );
    });

    test('a code the server rejects as malformed (400) is the same wrong code', () async {
      when(resolveCall).thenThrow(const ValidationException('Request rejected (400)'));

      await expectLater(
        repository.resolveSessionPublicId('FPTEDUVN-261010-K7QM-TOOLONG'),
        throwsA(isA<SessionResolutionException>()),
      );
    });
  });

  group('transport failures are not swallowed', () {
    for (final error in <ApiException>[
      const RateLimitException('Rate limited (429)'),
      const NetworkException('No connection'),
      const AuthException('Authentication failed (401)'),
    ]) {
      test('${error.runtimeType} propagates unchanged', () async {
        when(resolveCall).thenThrow(error);

        await expectLater(
          repository.resolveSessionPublicId(_canonicalCode),
          throwsA(same(error)),
        );
      });
    }
  });
}
