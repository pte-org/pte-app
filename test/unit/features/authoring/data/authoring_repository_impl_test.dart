import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/authoring/data/repositories/authoring_repository_impl.dart';
import 'package:pte_app/features/authoring/domain/authoring_types.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late AuthoringRepositoryImpl repository;

  Map<String, dynamic> fixture(String id) => {
    'publicId': id,
    'pteTaskType': 'MC_READING_SINGLE',
    'section': 'READING',
    'visibility': 'PRIVATE',
    'tenantId': 'tenant-1',
    'status': 'DRAFT',
    'title': 'Question',
    'promptText': 'Choose one',
    'options': [
      {'publicId': 'option-1', 'text': 'A', 'correct': true, 'orderIndex': 0},
      {'publicId': 'option-2', 'text': 'B', 'correct': false, 'orderIndex': 1},
    ],
    'skills': ['READING'],
  };

  setUp(() {
    apiClient = _MockApiClient();
    repository = AuthoringRepositoryImpl(apiClient: apiClient);
  });

  test('loadQuestions maps the authoritative GET response', () async {
    when(
      () => apiClient.get<List<dynamic>>('/api/authoring/questions'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/authoring/questions'),
        data: [fixture('question-1'), fixture('question-2')],
      ),
    );

    final questions = await repository.loadQuestions();

    expect(questions.map((question) => question.publicId), [
      'question-1',
      'question-2',
    ]);
  });

  test(
    'create sends exact private MC payload and maps backend-created entity',
    () async {
      Object? capturedData;
      when(
        () => apiClient.post<Map<String, dynamic>>(
          '/api/authoring/questions',
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        capturedData = invocation.namedArguments[#data];
        return Response(
          requestOptions: RequestOptions(path: '/api/authoring/questions'),
          data: fixture('created-1'),
        );
      });
      final input = CreateMcReadingSingleInput(
        title: 'Question',
        promptText: 'Choose one',
        options: const [
          QuestionOptionInput(text: 'A', correct: true, orderIndex: 0),
          QuestionOptionInput(text: 'B', correct: false, orderIndex: 1),
        ],
      );

      final created = await repository.createMcReadingSingle(input);

      expect(created.publicId, 'created-1');
      expect(capturedData, {
        'pteTaskType': 'MC_READING_SINGLE',
        'visibility': 'PRIVATE',
        'title': 'Question',
        'promptText': 'Choose one',
        'options': [
          {'text': 'A', 'correct': true, 'orderIndex': 0},
          {'text': 'B', 'correct': false, 'orderIndex': 1},
        ],
      });
    },
  );
}
