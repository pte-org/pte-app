import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/report/data/repositories/report_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late ReportRepositoryImpl repository;

  const path = '/api/reporting/reports/attempts/attempt-1';

  Map<String, dynamic> skillJson(String skill, {int? score, bool sufficientData = true}) =>
      {'skill': skill, 'score': score, 'sufficientData': sufficientData};

  setUp(() {
    apiClient = _MockApiClient();
    repository = ReportRepositoryImpl(apiClient: apiClient);
  });

  test('Step 7 precondition: a 404 (NotFoundException) from ApiClient is caught and returns null, never rethrown', () async {
    when(() => apiClient.get<Map<String, dynamic>>(path)).thenThrow(const NotFoundException('REPORT_NOT_FOUND'));

    final result = await repository.fetchReport('attempt-1');

    expect(result, isNull);
  });

  test('a 200 response is parsed into a ReportResponse', () async {
    when(() => apiClient.get<Map<String, dynamic>>(path)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'attemptPublicId': 'attempt-1',
          'sessionPublicId': 'session-1',
          'published': true,
          'publishedAt': '2026-07-20T10:00:00.000Z',
          'overall': skillJson('Overall', score: 65),
          'communicativeSkills': [skillJson('Reading', score: 70)],
          'enablingSkills': [skillJson('Grammar', score: 80)],
        },
      ),
    );

    final result = await repository.fetchReport('attempt-1');

    expect(result, isNotNull);
    expect(result!.attemptPublicId, 'attempt-1');
    expect(result.overall.score, 65);
    expect(result.communicativeSkills.single.skill, 'Reading');
  });

  test(
    'Step 8 precondition: any other exception (network error, 500/UnknownApiException) propagates unchanged rather than being swallowed',
    () async {
      when(() => apiClient.get<Map<String, dynamic>>(path)).thenThrow(const NetworkException('connection refused'));

      expect(() => repository.fetchReport('attempt-1'), throwsA(isA<NetworkException>()));
    },
  );

  test('a 500 (UnknownApiException) propagates unchanged, distinct from the 404-to-null mapping', () async {
    when(() => apiClient.get<Map<String, dynamic>>(path)).thenThrow(const UnknownApiException('server error'));

    expect(() => repository.fetchReport('attempt-1'), throwsA(isA<UnknownApiException>()));
  });
}
