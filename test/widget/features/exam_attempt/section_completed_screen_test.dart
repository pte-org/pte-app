import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/section_completed_screen.dart';

void main() {
  Widget buildSubject({required bool timeExpired, VoidCallback? onContinue}) {
    return MaterialApp(
      home: SectionCompletedScreen(
        timeExpired: timeExpired,
        attemptNumber: 1,
        remainingRetries: 0,
        canRetry: false,
        onContinue: onContinue ?? () {},
        onRetry: () {},
      ),
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

  testWidgets('with retries left, shows the remaining count and Try again calls onRetry', (
    tester,
  ) async {
    var retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SectionCompletedScreen(
          timeExpired: false,
          attemptNumber: 1,
          remainingRetries: 3,
          canRetry: true,
          onContinue: () {},
          onRetry: () => retryCount++,
        ),
      ),
    );

    expect(find.text(AppStrings.examRetriesRemainingMessage), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(ExamAttemptStrings.retryLimitReachedMessage), findsNothing);

    await tester.tap(find.text(ExamAttemptStrings.attemptStartRetry));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('with no retries left, shows the limit message and no Try again', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(timeExpired: false));

    expect(find.text(ExamAttemptStrings.retryLimitReachedMessage), findsOneWidget);
    expect(find.text(ExamAttemptStrings.attemptStartRetry), findsNothing);
  });

  testWidgets('tapping Continue calls onContinue exactly once', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(buildSubject(timeExpired: false, onContinue: () => callCount++));

    await tester.tap(find.text(AppStrings.sectionCompletedContinueButton));
    await tester.pump();

    expect(callCount, 1);
  });
}
