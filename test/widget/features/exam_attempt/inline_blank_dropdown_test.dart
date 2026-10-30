import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/inline_blank_dropdown.dart';

void main() {
  testWidgets(
    'menu opens below the blank at matching width with compact rounded chrome',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InlineBlankDropdown(
                width: 180,
                value: null,
                options: const [
                  InlineBlankChoice(value: '0', text: 'delivered'),
                  InlineBlankChoice(value: '1', text: 'managed'),
                ],
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      final anchor = tester.getRect(find.byType(InlineBlankDropdown));
      await tester.tap(find.byType(InlineBlankDropdown));
      await tester.pumpAndSettle();
      final firstRow = tester.getRect(find.byType(MenuItemButton).first);
      expect(firstRow.top, greaterThanOrEqualTo(anchor.bottom));
      expect(firstRow.left, closeTo(anchor.left, 1));
      expect(firstRow.width, closeTo(anchor.width, 1));
      expect(firstRow.height, lessThanOrEqualTo(36));
      final style = tester.widget<MenuAnchor>(find.byType(MenuAnchor)).style!;
      expect(style.elevation!.resolve({}), 0);
      final shape = style.shape!.resolve({})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(6));
      await tester.tap(find.text('managed'));
      await tester.pumpAndSettle();
      expect(selected, '1');
      expect(find.byType(MenuItemButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Escape closes the menu without changing the saved choice', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: InlineBlankDropdown(
              width: 160,
              value: '0',
              options: const [
                InlineBlankChoice(value: '0', text: 'related'),
                InlineBlankChoice(value: '1', text: 'directed'),
              ],
              onChanged: (_) => changes++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InlineBlankDropdown));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
    expect(find.text('related'), findsOneWidget);
    expect(changes, 0);
    expect(tester.takeException(), isNull);
  });
}
