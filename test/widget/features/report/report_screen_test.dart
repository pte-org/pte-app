import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/report/domain/report_response.dart';
import 'package:pte_app/features/report/domain/repositories/report_repository.dart';
import 'package:pte_app/features/report/presentation/pages/report_screen.dart';
import 'package:pte_app/features/report/constants/report_strings.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

/// Full 4-skill report — Overall present.
ReportResponse _reportWithOverall() {
  return const ReportResponse(
    attemptPublicId: 'attempt-1',
    sessionPublicId: 'session-1',
    published: true,
    publishedAt: null,
    overall: SkillScoreResponse(skill: 'OverallScore', score: 65, sufficientData: true),
    communicativeSkills: [SkillScoreResponse(skill: 'Reading', score: 70, sufficientData: true)],
  );
}

/// Partial-skill report (spec FR-20: fewer than 4 skills tested) — `overall`
/// is `null`, not just `sufficientData: false`.
ReportResponse _reportWithoutOverall() {
  return const ReportResponse(
    attemptPublicId: 'attempt-1',
    sessionPublicId: 'session-1',
    published: true,
    publishedAt: null,
    overall: null,
    communicativeSkills: [
      SkillScoreResponse(skill: 'Reading', score: 70, sufficientData: true),
      SkillScoreResponse(skill: 'Speaking', score: null, sufficientData: false),
    ],
  );
}

void main() {
  late _MockReportRepository repository;

  setUp(() {
    repository = _MockReportRepository();
  });

  Widget buildSubject() {
    return MaterialApp(home: ReportScreen(attemptPublicId: 'attempt-1', repository: repository));
  }

  testWidgets('Step 7 — a null repository result (404) renders the not-published view, not the error view', (
    tester,
  ) async {
    when(() => repository.fetchReport('attempt-1')).thenAnswer((_) async => null);

    await tester.pumpWidget(buildSubject());
    await tester.pump(); // let initState's ReportRequested resolve

    expect(find.text(ReportStrings.reportNotPublishedTitle), findsOneWidget);
    expect(find.text(ReportStrings.reportErrorTitle), findsNothing);
  });

  testWidgets('Step 8 — a thrown network error renders the error view, distinct from the not-published view', (
    tester,
  ) async {
    when(() => repository.fetchReport('attempt-1')).thenThrow(const NetworkException('connection refused'));

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text(ReportStrings.reportErrorTitle), findsOneWidget);
    expect(find.text(ReportStrings.reportNotPublishedTitle), findsNothing);
  });

  testWidgets('a full 4-skill report renders Overall + Communicative skills, no Enabling skills section at all', (
    tester,
  ) async {
    when(() => repository.fetchReport('attempt-1')).thenAnswer((_) async => _reportWithOverall());

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text(ReportStrings.reportOverallSectionTitle), findsOneWidget);
    expect(find.text(ReportStrings.reportCommunicativeSkillsSectionTitle), findsOneWidget);
    expect(find.text('65'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    // No enabling-skills string constant exists at all any more (compile-time
    // proof via ReportStrings not referencing it) — runtime proof that no
    // stray "Enabling skills" text ever renders regardless of wording.
    expect(find.textContaining('Enabling'), findsNothing);
  });

  testWidgets('a partial-skill report (overall == null) hides the Overall section but still shows tested skills', (
    tester,
  ) async {
    when(() => repository.fetchReport('attempt-1')).thenAnswer((_) async => _reportWithoutOverall());

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text(ReportStrings.reportOverallSectionTitle), findsNothing);
    expect(find.text(ReportStrings.reportCommunicativeSkillsSectionTitle), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text(ReportStrings.reportInsufficientDataLabel), findsOneWidget);
  });

  testWidgets('pull-to-refresh dispatches ReportRefreshRequested and can transition NotPublished -> Ready', (
    tester,
  ) async {
    var callCount = 0;
    when(() => repository.fetchReport('attempt-1')).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? null : _reportWithOverall();
    });

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text(ReportStrings.reportNotPublishedTitle), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(find.text(ReportStrings.reportOverallSectionTitle), findsOneWidget);
    verify(() => repository.fetchReport('attempt-1')).called(2);
  });

  testWidgets('closes the ReportBloc on dispose without throwing', (tester) async {
    when(() => repository.fetchReport('attempt-1')).thenAnswer((_) async => _reportWithOverall());

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
