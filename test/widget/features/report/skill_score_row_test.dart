import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/report/domain/report_response.dart';
import 'package:pte_app/features/report/presentation/widgets/skill_score_row.dart';

void main() {
  Widget buildSubject(SkillScoreResponse skillScore) {
    return MaterialApp(home: Scaffold(body: SkillScoreRow(skillScore: skillScore)));
  }

  group('Step 9 — sufficientData:false with a non-null score still renders "insufficient data"', () {
    testWidgets('a score of 75 alongside sufficientData:false renders the insufficient-data label, not "75"', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(const SkillScoreResponse(skill: 'Speaking', score: 75, sufficientData: false)),
      );

      expect(find.text(AppStrings.reportInsufficientDataLabel), findsOneWidget);
      expect(find.text('75'), findsNothing);
    });

    testWidgets('a null score alongside sufficientData:false also renders the insufficient-data label', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(const SkillScoreResponse(skill: 'Speaking', score: null, sufficientData: false)),
      );

      expect(find.text(AppStrings.reportInsufficientDataLabel), findsOneWidget);
    });
  });

  group('Step 10 — sufficientData:true with a valid score renders the numeric value distinctly', () {
    testWidgets('renders the numeric score as a bold Text, structurally distinct from the insufficient-data style', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(const SkillScoreResponse(skill: 'Reading', score: 82, sufficientData: true)),
      );

      expect(find.text('82'), findsOneWidget);
      expect(find.text(AppStrings.reportInsufficientDataLabel), findsNothing);

      final scoreText = tester.widget<Text>(find.text('82'));
      expect(scoreText.style?.fontWeight, FontWeight.bold);
      expect(scoreText.style?.fontStyle, isNot(FontStyle.italic));
    });

    testWidgets('the insufficient-data branch renders italic style, not bold — structurally distinct widgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(const SkillScoreResponse(skill: 'Speaking', score: null, sufficientData: false)),
      );

      final label = tester.widget<Text>(find.text(AppStrings.reportInsufficientDataLabel));
      expect(label.style?.fontStyle, FontStyle.italic);
      expect(label.style?.fontWeight, isNot(FontWeight.bold));
    });
  });

  testWidgets('renders the skill name alongside the score/label', (tester) async {
    await tester.pumpWidget(
      buildSubject(const SkillScoreResponse(skill: 'Grammar', score: 60, sufficientData: true)),
    );

    expect(find.text('Grammar'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
  });
}
