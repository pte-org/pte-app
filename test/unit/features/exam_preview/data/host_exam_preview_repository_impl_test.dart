import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/exam_preview/data/repositories/host_exam_preview_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

Response<T> _response<T>(T data, String path) => Response<T>(
  requestOptions: RequestOptions(path: path),
  statusCode: 200,
  data: data,
);

void main() {
  late _MockApiClient apiClient;
  late HostExamPreviewRepositoryImpl repository;

  setUp(() {
    apiClient = _MockApiClient();
    repository = HostExamPreviewRepositoryImpl(apiClient: apiClient);
  });

  test(
    'lists owned sessions through the read-only sessions endpoint',
    () async {
      when(() => apiClient.get<List<dynamic>>('/api/v1/sessions')).thenAnswer(
        (_) async => _response([
          {
            'publicId': 'session-1',
            'sessionCode': 'E2E-0001',
            'name': 'Ready exam',
            'status': 'READY',
            'examVersionPublicId': 'snapshot-1',
          },
          {
            'publicId': 'session-2',
            'sessionCode': 'E2E-0002',
            'name': 'Draft exam',
            'status': 'DRAFT',
            'examVersionPublicId': null,
          },
        ], '/api/v1/sessions'),
      );

      final result = await repository.listExams();

      expect(result, hasLength(2));
      expect(result.first.canPreview, isTrue);
      expect(result.last.canPreview, isFalse);
      verify(() => apiClient.get<List<dynamic>>('/api/v1/sessions')).called(1);
    },
  );

  test(
    'parses preview items without answer-bearing fields and preserves option order',
    () async {
      const path = '/api/v1/sessions/session-1/exam-preview';
      when(() => apiClient.get<Map<String, dynamic>>(path)).thenAnswer(
        (_) async => _response({
          'snapshotPublicId': 'snapshot-1',
          'name': 'Ready exam',
          'version': 3,
          'items': [
            {
              'orderIndex': 0,
              'snapshotItemPublicId': 'item-1',
              'sourceQuestionPublicId': 'question-1',
              'section': 'READING',
              'taskType': 'MC_READING_SINGLE',
              'taskTypeCode': 'MC_READING_SINGLE',
              'taskTypeDisplayName': 'Multiple choice',
              'title': 'Question',
              'promptText': 'Choose one.',
              'options': [
                {'orderIndex': 1, 'blankIndex': null, 'text': 'Second'},
                {'orderIndex': 0, 'blankIndex': null, 'text': 'First'},
              ],
              'prepSeconds': 0,
              'responseSeconds': 30,
            },
          ],
        }, path),
      );

      final snapshot = await repository.fetchPreview('session-1');

      expect(snapshot.snapshotPublicId, 'snapshot-1');
      expect(snapshot.items.single.snapshotItemPublicId, 'item-1');
      expect(snapshot.items.single.options.map((option) => option.text), [
        'Second',
        'First',
      ]);
      expect(snapshot.items.single.runtime, isNull);
      verify(() => apiClient.get<Map<String, dynamic>>(path)).called(1);
    },
  );

  test('rejects an empty session identifier before making a request', () async {
    expect(
      () => repository.fetchPreview('  '),
      throwsA(isA<FormatException>()),
    );
    verifyNever(() => apiClient.get<Map<String, dynamic>>(any()));
  });
}
