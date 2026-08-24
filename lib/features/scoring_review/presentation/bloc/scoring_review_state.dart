import '../../domain/scoring_review_types.dart';

sealed class ScoringReviewState {
  const ScoringReviewState();
}

final class ScoringReviewInitial extends ScoringReviewState {
  const ScoringReviewInitial();
}

final class ScoringReviewLoading extends ScoringReviewState {
  const ScoringReviewLoading();
}

final class ScoringReviewEmpty extends ScoringReviewState {
  const ScoringReviewEmpty(this.page);
  final ScoringReviewPage page;
}

base class ScoringReviewData extends ScoringReviewState {
  const ScoringReviewData(this.page);
  final ScoringReviewPage page;
}

final class ScoringReviewLoaded extends ScoringReviewData {
  const ScoringReviewLoaded(super.page);
}

final class ScoringReviewLoadingMore extends ScoringReviewData {
  const ScoringReviewLoadingMore(super.page);
}

final class ScoringReviewRefreshing extends ScoringReviewData {
  const ScoringReviewRefreshing(super.page);
}

final class ScoringReviewCommandRunning extends ScoringReviewData {
  const ScoringReviewCommandRunning(super.page);
}

final class ScoringReviewCommandSuccess extends ScoringReviewData {
  const ScoringReviewCommandSuccess(super.page, this.command);
  final String command;
}

final class ScoringReviewFailure extends ScoringReviewState {
  const ScoringReviewFailure(this.error, {this.page});
  final Object error;
  final ScoringReviewPage? page;
}
