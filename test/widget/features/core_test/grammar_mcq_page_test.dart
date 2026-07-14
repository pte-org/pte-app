import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/features/core_test/presentation/pages/grammar_mcq_page.dart';

void main() {
  // Counts the filled radio inner dots. Constrained to the radio inner-dot
  // size so it does not match the brand's (same-lime) logo dots in the app bar.
  Finder filledDots() => find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final decoration = widget.decoration;
    if (decoration is! BoxDecoration) return false;
    final constraints = widget.constraints;
    return decoration.color == AppColors.primaryLime &&
        decoration.shape == BoxShape.circle &&
        constraints != null &&
        constraints.maxWidth == AppDimensions.mcqRadioInnerSize;
  });

  testWidgets('Q1 MCQ keeps a single selection in the real question', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GrammarMcqPage()));

    // Only the pre-answered example is selected initially.
    expect(filledDots(), findsOneWidget);

    await tester.ensureVisible(find.text('which'));
    await tester.tap(find.text('which'));
    await tester.pump();

    // Example + the newly selected "which".
    expect(filledDots(), findsNWidgets(2));

    await tester.ensureVisible(find.text('that'));
    await tester.tap(find.text('that'));
    await tester.pump();

    // Still exactly two: selecting "that" replaces "which" (single-select).
    expect(filledDots(), findsNWidgets(2));
  });
}
