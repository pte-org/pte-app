import '../repositories/scoring_review_repository.dart';
import '../scoring_review_types.dart';

class RequestScoring {
  const RequestScoring({required ScoringReviewRepository repository})
    : _repository = repository;

  final ScoringReviewRepository _repository;

  Future<void> call(String sessionPublicId) =>
      _repository.requestScoring(sessionPublicId);
}

class LoadPendingReviews {
  const LoadPendingReviews({required ScoringReviewRepository repository})
    : _repository = repository;

  final ScoringReviewRepository _repository;

  Future<ScoringReviewPage> call(String sessionPublicId, int page, int size) =>
      _repository.loadPendingReviews(sessionPublicId, page: page, size: size);
}

class ApproveReview {
  const ApproveReview({required ScoringReviewRepository repository})
    : _repository = repository;

  final ScoringReviewRepository _repository;

  Future<ScoringReviewAnswer> call(String answerPublicId) =>
      _repository.approveReview(answerPublicId);
}

class PublishResults {
  const PublishResults({required ScoringReviewRepository repository})
    : _repository = repository;

  final ScoringReviewRepository _repository;

  Future<void> call(String sessionPublicId) =>
      _repository.publishResults(sessionPublicId);
}
