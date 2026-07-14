import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/features/core_test/presentation/pages/sentence_completion_page.dart';

void main() {
  testWidgets('Q28 sentence dropdown keeps the chosen word', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SentenceCompletionPage()),
    );

    final firstWord = AppStrings.sentenceCompletionWordBank.first;

    // Open the first sentence's dropdown.
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();

    // Choose the first bank word from the opened menu.
    await tester.tap(find.text(firstWord).last);
    await tester.pumpAndSettle();

    // The chosen word is now displayed as the dropdown value.
    expect(find.text(firstWord), findsOneWidget);
  });
}
