sealed class ScoringReviewEvent {
  const ScoringReviewEvent();
}

final class ScoringReviewRequested extends ScoringReviewEvent {
  const ScoringReviewRequested(this.sessionPublicId);
  final String sessionPublicId;
}

final class ScoringReviewNextPageRequested extends ScoringReviewEvent {
  const ScoringReviewNextPageRequested(this.sessionPublicId);
  final String sessionPublicId;
}

final class ScoringReviewApprovalRequested extends ScoringReviewEvent {
  const ScoringReviewApprovalRequested(
    this.sessionPublicId,
    this.answerPublicId,
  );
  final String sessionPublicId;
  final String answerPublicId;
}

final class SessionScoringRequested extends ScoringReviewEvent {
  const SessionScoringRequested(this.sessionPublicId);
  final String sessionPublicId;
}

final class SessionPublishRequested extends ScoringReviewEvent {
  const SessionPublishRequested(this.sessionPublicId);
  final String sessionPublicId;
}
