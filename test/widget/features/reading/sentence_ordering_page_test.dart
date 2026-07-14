import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/features/reading/presentation/pages/sentence_ordering_page.dart';

void main() {
  // Render smoke test — drag reordering is verified in the visual walkthrough.
  testWidgets('R2 renders the fixed example and the orderable sentences', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SentenceOrderingPage()));

    expect(find.text(AppStrings.readingOrderingExample), findsOneWidget);
    for (final sentence in AppStrings.readingOrderingSentences) {
      expect(find.text(sentence), findsOneWidget);
    }
  });
}
