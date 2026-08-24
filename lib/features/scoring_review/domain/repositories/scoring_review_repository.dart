import '../scoring_review_types.dart';

abstract interface class ScoringReviewRepository {
  Future<void> requestScoring(String sessionPublicId);

  Future<ScoringReviewPage> loadPendingReviews(
    String sessionPublicId, {
    int page = 0,
    int size = 20,
  });

  Future<ScoringReviewAnswer> approveReview(String answerPublicId);

  Future<void> publishResults(String sessionPublicId);
}
