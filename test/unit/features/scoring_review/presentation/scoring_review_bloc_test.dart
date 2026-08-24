import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/scoring_review/domain/scoring_review_types.dart';
import 'package:pte_app/features/scoring_review/domain/usecases/manage_scoring.dart';
import 'package:pte_app/features/scoring_review/presentation/bloc/scoring_review_bloc.dart';
import 'package:pte_app/features/scoring_review/presentation/bloc/scoring_review_event.dart';
import 'package:pte_app/features/scoring_review/presentation/bloc/scoring_review_state.dart';

class _MockLoadPendingReviews extends Mock implements LoadPendingReviews {}

class _MockApproveReview extends Mock implements ApproveReview {}

class _MockRequestScoring extends Mock implements RequestScoring {}

class _MockPublishResults extends Mock implements PublishResults {}

void main() {
  late _MockLoadPendingReviews loadPending;
  late _MockApproveReview approve;
  late _MockRequestScoring requestScoring;
  late _MockPublishResults publish;

  const answer = ScoringReviewAnswer(
    answerPublicId: 'answer-1',
    attemptPublicId: 'attempt-1',
    taskType: 'WRITE_ESSAY',
    status: 'AI_SCORED_PENDING_REVIEW',
    rawScore: 72,
  );
  const page = ScoringReviewPage(
    items: [answer],
    page: 0,
    size: 20,
    totalElements: 1,
    totalPages: 1,
  );

  setUp(() {
    loadPending = _MockLoadPendingReviews();
    approve = _MockApproveReview();
    requestScoring = _MockRequestScoring();
    publish = _MockPublishResults();
  });

  ScoringReviewBloc buildBloc() => ScoringReviewBloc(
    loadPendingReviews: loadPending,
    approveReview: approve,
    requestScoring: requestScoring,
    publishResults: publish,
  );

  blocTest<ScoringReviewBloc, ScoringReviewState>(
    'loads pending queue',
    setUp: () => when(
      () => loadPending('session-1', 0, 20),
    ).thenAnswer((_) async => page),
    build: buildBloc,
    act: (bloc) => bloc.add(const ScoringReviewRequested('session-1')),
    expect: () => [
      isA<ScoringReviewLoading>(),
      isA<ScoringReviewLoaded>().having(
        (state) => state.page.totalElements,
        'totalElements',
        1,
      ),
    ],
  );

  blocTest<ScoringReviewBloc, ScoringReviewState>(
    'approval reloads authoritative queue instead of mutating locally',
    setUp: () {
      when(() => approve('answer-1')).thenAnswer((_) async => answer);
      when(() => loadPending('session-1', 0, 20)).thenAnswer(
        (_) async => const ScoringReviewPage(
          items: [],
          page: 0,
          size: 20,
          totalElements: 0,
          totalPages: 0,
        ),
      );
    },
    seed: () => const ScoringReviewLoaded(page),
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const ScoringReviewApprovalRequested('session-1', 'answer-1')),
    expect: () => [isA<ScoringReviewRefreshing>(), isA<ScoringReviewEmpty>()],
    verify: (_) {
      verify(() => approve('answer-1')).called(1);
      verify(() => loadPending('session-1', 0, 20)).called(1);
    },
  );
}
