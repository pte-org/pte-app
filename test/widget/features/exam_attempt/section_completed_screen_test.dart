import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/section_completed_screen.dart';

void main() {
  Widget buildSubject({required bool timeExpired, VoidCallback? onContinue}) {
    return MaterialApp(
      home: SectionCompletedScreen(timeExpired: timeExpired, onContinue: onContinue ?? () {}),
    );
  }

  testWidgets('timeExpired: true renders the "Time is up" wording, not the natural-completion wording', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(timeExpired: true));

    expect(find.text(AppStrings.sectionCompletedTimeUpTitle), findsOneWidget);
    expect(find.text(AppStrings.sectionCompletedNaturalTitle), findsNothing);
  });

  testWidgets('timeExpired: false renders the natural-completion wording, not the "Time is up" wording', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(timeExpired: false));

    expect(find.text(AppStrings.sectionCompletedNaturalTitle), findsOneWidget);
    expect(find.text(AppStrings.sectionCompletedTimeUpTitle), findsNothing);
  });

  testWidgets('tapping Continue calls onContinue exactly once', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(buildSubject(timeExpired: false, onContinue: () => callCount++));

    await tester.tap(find.text(AppStrings.sectionCompletedContinueButton));
    await tester.pump();

    expect(callCount, 1);
  });
}
