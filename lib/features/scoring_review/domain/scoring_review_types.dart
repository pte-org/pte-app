class ScoringReviewAnswer {
  const ScoringReviewAnswer({
    required this.answerPublicId,
    required this.attemptPublicId,
    required this.taskType,
    required this.status,
    required this.rawScore,
  });

  final String answerPublicId;
  final String attemptPublicId;
  final String taskType;
  final String status;
  final int? rawScore;
}

class ScoringReviewPage {
  const ScoringReviewPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<ScoringReviewAnswer> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasNextPage => page + 1 < totalPages;
}
