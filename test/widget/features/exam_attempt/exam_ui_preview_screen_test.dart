import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/widgets/components/in_text_select.dart';
import 'package:pte_app/core/widgets/components/record_response_card.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_catalog.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_screen.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_task_body.dart';

void main() {
  testWidgets('opens an offline catalog task screen without side effects', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExamUiPreviewScreen()));

    await tester.tap(find.byType(ListTile).first);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Save & Exit'), findsOneWidget);
    expect(find.text('Item 1 of 23'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Item 2 of 23'), findsOneWidget);
    await tester.tap(find.text('Save & Exit'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders inline controls for dropdown blank fixtures', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExamUiPreviewTaskBody(
            model: ExamUiPreviewCatalog.modelFor('FILL_BLANKS_READING_WRITING'),
          ),
        ),
      ),
    );

    expect(find.byType(InTextSelect), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the complete offline recorded-answer state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExamUiPreviewTaskBody(
            model: ExamUiPreviewCatalog.modelFor('PERSONAL_INTRODUCTION'),
          ),
        ),
      ),
    );

    expect(find.byType(RecordResponseCard), findsOneWidget);
    expect(find.text('Microphone Guidelines'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
