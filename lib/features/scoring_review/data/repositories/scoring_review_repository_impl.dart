import '../../../../core/network/api_client.dart';
import '../../domain/repositories/scoring_review_repository.dart';
import '../../domain/scoring_review_types.dart';
import '../models/scoring_review_models.dart';

class ScoringReviewRepositoryImpl implements ScoringReviewRepository {
  ScoringReviewRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  static const _sessionsPath = '/api/scheduling/sessions';
  static const _answersPath = '/api/scoring/answers';
  static const _pendingStatus = 'AI_SCORED_PENDING_REVIEW';

  final ApiClient _apiClient;

  @override
  Future<void> requestScoring(String sessionPublicId) async {
    await _apiClient.post<void>('$_sessionsPath/$sessionPublicId/score');
  }

  @override
  Future<ScoringReviewPage> loadPendingReviews(
    String sessionPublicId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_answersPath/reviews',
      queryParameters: {
        'sessionPublicId': sessionPublicId,
        'status': _pendingStatus,
        'page': page,
        'size': size,
      },
    );
    return ScoringReviewPageModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<ScoringReviewAnswer> approveReview(String answerPublicId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_answersPath/$answerPublicId/review',
    );
    return ScoringReviewAnswerModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<void> publishResults(String sessionPublicId) async {
    await _apiClient.post<void>('$_sessionsPath/$sessionPublicId/publish');
  }
}
