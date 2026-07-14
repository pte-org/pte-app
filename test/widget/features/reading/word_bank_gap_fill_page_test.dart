import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/features/reading/presentation/pages/word_bank_gap_fill_page.dart';

void main() {
  // Render smoke test — the drag-to-fill behaviour is verified in the visual
  // walkthrough (Draggable/DragTarget drops are unreliable in widget tests).
  testWidgets('R3 renders the passage, the fixed gap, and the word bank', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WordBankGapFillPage()));

    expect(find.text(AppStrings.readingWordBankTitle), findsOneWidget);
    // The first gap is pre-filled with the fixed answer.
    expect(find.text(AppStrings.readingWordBankFirstAnswer), findsOneWidget);
    // A distractor tile that is only in the bank.
    expect(find.text('taking'), findsOneWidget);
  });
}
