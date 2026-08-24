import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/reading_instructions_screen.dart';

void main() {
  Widget buildSubject(VoidCallback onContinue) {
    return MaterialApp(home: ReadingInstructionsScreen(onContinue: onContinue));
  }

  testWidgets('renders the instructions body text', (tester) async {
    await tester.pumpWidget(buildSubject(() {}));

    expect(find.text(AppStrings.readingInstructionsBody), findsOneWidget);
  });

  testWidgets('tapping Next calls onContinue exactly once', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(buildSubject(() => callCount++));

    await tester.tap(find.text(AppStrings.readingInstructionsButtonLabel));
    await tester.pump();

    expect(callCount, 1);
  });
}
