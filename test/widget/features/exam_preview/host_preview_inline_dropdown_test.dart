import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/inline_blank_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart';

void main() {
  for (final width in [375.0, 1280.0]) {
    testWidgets(
      'host dropdowns stay inside the passage and retain independent answers at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final model = PreviewTaskUiAdapter.adapt(
          const PreviewItem(
            orderIndex: 0,
            snapshotItemPublicId: 'item',
            sourceQuestionPublicId: 'question',
            section: 'READING',
            taskType: 'FILL_IN_THE_BLANKS_DROPDOWN',
            taskTypeCode: 'FILL_IN_THE_BLANKS_DROPDOWN',
            taskTypeDisplayName: null,
            title: null,
            promptText:
                'It was {{1}} but {{2}}.\nThe next paragraph remains readable.',
            audioUrl: null,
            imageUrl: null,
            minWordCount: null,
            maxWordCount: null,
            options: [
              PreviewOption(orderIndex: 0, blankIndex: 0, text: 'sunny'),
              PreviewOption(orderIndex: 1, blankIndex: 0, text: 'rainy'),
              PreviewOption(orderIndex: 2, blankIndex: 1, text: 'cold'),
              PreviewOption(orderIndex: 3, blankIndex: 1, text: 'warm'),
            ],
            runtime: null,
            runtimeMappingVersion: null,
            runtimeMappingStatus: null,
            prepSeconds: 0,
            responseSeconds: 60,
            preListenSeconds: null,
            preRecordSeconds: null,
            audioDurationSeconds: null,
            audioUrlExpiresAt: null,
            imageUrlExpiresAt: null,
          ),
        );
        Object? answer;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => HostPreviewTaskDispatcher(
                  model: model,
                  answer: answer,
                  onAnswerChanged: (next) => setState(() => answer = next),
                ),
              ),
            ),
          ),
        );
        final passage = find.byKey(const ValueKey('inlineBlankPassage'));
        expect(passage, findsOneWidget);
        final span = tester.widget<Text>(passage).textSpan!;
        expect(span.toPlainText(), isNot(contains('{{')));
        expect(span.toPlainText(), contains('The next paragraph'));
        expect(
          find.descendant(
            of: passage,
            matching: find.byType(InlineBlankDropdown),
          ),
          findsNWidgets(2),
        );
        expect(find.text('Blank 1'), findsNothing);
        expect(find.byType(SelectableText), findsNothing);
        await tester.tap(find.byKey(const ValueKey('inlineBlank-0')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('rainy').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('inlineBlank-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('warm').last);
        await tester.pumpAndSettle();
        expect(answer, {0: 'rainy', 1: 'warm'});
        expect(
          tester
              .widget<InlineBlankDropdown>(
                find.byKey(const ValueKey('inlineBlank-0')),
              )
              .value,
          'rainy',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
