import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/scoring_review/data/repositories/scoring_review_repository_impl.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late ScoringReviewRepositoryImpl repository;

  setUp(() {
    apiClient = _MockApiClient();
    repository = ScoringReviewRepositoryImpl(apiClient: apiClient);
  });

  test(
    'uses exact score, pending review, approve, and publish contracts',
    () async {
      for (final action in ['score', 'publish']) {
        when(
          () => apiClient.post<void>(
            '/api/scheduling/sessions/session-1/$action',
          ),
        ).thenAnswer(
          (_) async => Response(requestOptions: RequestOptions(path: '')),
        );
      }
      when(
        () => apiClient.get<Map<String, dynamic>>(
          '/api/scoring/answers/reviews',
          queryParameters: {
            'sessionPublicId': 'session-1',
            'status': 'AI_SCORED_PENDING_REVIEW',
            'page': 0,
            'size': 20,
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'items': [
              {
                'answerPublicId': 'answer-1',
                'attemptPublicId': 'attempt-1',
                'taskType': 'WRITE_ESSAY',
                'status': 'AI_SCORED_PENDING_REVIEW',
                'rawScore': 72,
              },
            ],
            'page': 0,
            'size': 20,
            'totalElements': 1,
            'totalPages': 1,
          },
        ),
      );
      when(
        () => apiClient.post<Map<String, dynamic>>(
          '/api/scoring/answers/answer-1/review',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'answerPublicId': 'answer-1',
            'attemptPublicId': 'attempt-1',
            'taskType': 'WRITE_ESSAY',
            'status': 'SCORED',
            'rawScore': 72,
          },
        ),
      );

      await repository.requestScoring('session-1');
      final page = await repository.loadPendingReviews('session-1');
      final reviewed = await repository.approveReview('answer-1');
      await repository.publishResults('session-1');

      expect(page.items.single.answerPublicId, 'answer-1');
      expect(page.totalElements, 1);
      expect(reviewed.status, 'SCORED');
    },
  );
}
