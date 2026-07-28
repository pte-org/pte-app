import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/scoring_review/domain/scoring_review_types.dart';
import 'package:pte_app/features/scoring_review/presentation/bloc/scoring_review_bloc.dart';
import 'package:pte_app/features/scoring_review/presentation/bloc/scoring_review_event.dart';
import 'package:pte_app/features/scoring_review/presentation/bloc/scoring_review_state.dart';
import 'package:pte_app/features/scoring_review/presentation/pages/session_scoring_page.dart';

class _MockScoringReviewBloc
    extends MockBloc<ScoringReviewEvent, ScoringReviewState>
    implements ScoringReviewBloc {}

void main() {
  const loaded = ScoringReviewLoaded(
    ScoringReviewPage(
      items: [
        ScoringReviewAnswer(
          answerPublicId: 'answer-1',
          attemptPublicId: 'attempt-1',
          taskType: 'WRITE_ESSAY',
          status: 'AI_SCORED_PENDING_REVIEW',
          rawScore: 72,
        ),
      ],
      page: 0,
      size: 20,
      totalElements: 1,
      totalPages: 1,
    ),
  );

  testWidgets('host author can review but cannot score or publish', (
    tester,
  ) async {
    final bloc = _MockScoringReviewBloc();
    when(() => bloc.state).thenReturn(loaded);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ScoringReviewBloc>.value(
          value: bloc,
          child: const SessionScoringPage(
            sessionPublicId: 'session-1',
            isAdmin: false,
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.approveReview), findsOneWidget);
    expect(find.text(AppStrings.requestScoring), findsNothing);
    expect(find.text(AppStrings.publishResults), findsNothing);
  });

  testWidgets('host admin sees score and publish commands', (tester) async {
    final bloc = _MockScoringReviewBloc();
    when(() => bloc.state).thenReturn(loaded);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ScoringReviewBloc>.value(
          value: bloc,
          child: const SessionScoringPage(
            sessionPublicId: 'session-1',
            isAdmin: true,
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.requestScoring), findsOneWidget);
    expect(find.text(AppStrings.publishResults), findsOneWidget);
  });
}
