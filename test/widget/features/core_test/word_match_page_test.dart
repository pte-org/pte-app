import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/features/core_test/presentation/pages/word_match_page.dart';

void main() {
  testWidgets('WordMatchPage keeps a chosen dropdown value', (tester) async {
    // No args -> defaults to the Q26 synonym content.
    await tester.pumpWidget(const MaterialApp(home: WordMatchPage()));

    final firstOption = AppStrings.vocabularySampleOptions.first.first;

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstOption).last);
    await tester.pumpAndSettle();

    expect(find.text(firstOption), findsOneWidget);
  });
}
