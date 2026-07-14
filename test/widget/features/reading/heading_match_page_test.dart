import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/features/reading/presentation/pages/heading_match_page.dart';

void main() {
  testWidgets('R4 heading match: a paragraph dropdown keeps its heading', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HeadingMatchPage()));

    final heading = AppStrings.readingHeadingOptions.first;

    final dropdown = find.byType(DropdownButton<String>).first;
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text(heading).last);
    await tester.pumpAndSettle();

    expect(find.text(heading), findsOneWidget);
  });
}
