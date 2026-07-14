import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aptis_app/features/reading/presentation/pages/gap_fill_message_page.dart';

void main() {
  testWidgets('R1 gap-fill: an editable line keeps its chosen word', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GapFillMessagePage()));

    // Line index 1 ("I have a work meeting __ 6:00pm.") — options at/on/in/by.
    final dropdown = find.byType(DropdownButton<String>).at(1);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('by').last);
    await tester.pumpAndSettle();

    expect(find.text('by'), findsOneWidget);
  });
}
