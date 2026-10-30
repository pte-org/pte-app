import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/widgets/components/choice_row.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart';

PreviewItem item(String type) => PreviewItem(
  orderIndex: 0,
  snapshotItemPublicId: 'i',
  sourceQuestionPublicId: 'q',
  section: 'READING',
  taskType: type,
  taskTypeCode: type,
  taskTypeDisplayName: null,
  title: null,
  promptText:
      'First passage paragraph.\nSecond passage paragraph.\n\nWhich answer is correct?',
  audioUrl: null,
  imageUrl: null,
  minWordCount: null,
  maxWordCount: null,
  options: const [
    PreviewOption(orderIndex: 8, blankIndex: null, text: 'Alpha'),
    PreviewOption(orderIndex: 2, blankIndex: null, text: 'Beta'),
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
);

void main() {
  for (final type in ['MC_READING_SINGLE', 'MC_READING_MULTIPLE']) {
    for (final width in [375.0, 1280.0]) {
      testWidgets(
        '$type separates passage and question at $width and keeps selections',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          Object? answer;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => HostPreviewTaskDispatcher(
                    model: PreviewTaskUiAdapter.adapt(item(type)),
                    answer: answer,
                    onAnswerChanged: (next) => setState(() => answer = next),
                  ),
                ),
              ),
            ),
          );
          final passage = find.byKey(const ValueKey('readingChoicePassage'));
          final response = find.byKey(const ValueKey('readingChoiceResponse'));
          expect(
            tester.widget<Text>(passage).data,
            'First passage paragraph.\nSecond passage paragraph.',
          );
          expect(find.text('Which answer is correct?'), findsOneWidget);
          if (width > 720) {
            expect(
              tester.getTopLeft(passage).dy,
              tester.getTopLeft(response).dy,
            );
            expect(
              tester.getTopLeft(response).dx,
              greaterThan(tester.getTopRight(passage).dx),
            );
          } else {
            expect(
              tester.getTopLeft(response).dy,
              greaterThan(tester.getBottomLeft(passage).dy),
            );
          }
          expect(
            tester
                .widgetList<ChoiceRow>(find.byType(ChoiceRow))
                .every((row) => row.plain),
            isTrue,
          );
          await tester.ensureVisible(find.text('Alpha'));
          await tester.tap(find.text('Alpha'));
          await tester.pump();
          await tester.ensureVisible(find.text('Beta'));
          await tester.tap(find.text('Beta'));
          await tester.pump();
          expect(answer, type == 'MC_READING_SINGLE' ? [1] : [0, 1]);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'host Reorder uses Source-Target and restores its controlled answer',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Object? answer = <int>[1];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => HostPreviewTaskDispatcher(
                model: PreviewTaskUiAdapter.adapt(item('RE_ORDER_PARAGRAPHS')),
                answer: answer,
                onAnswerChanged: (next) => setState(() => answer = next),
              ),
            ),
          ),
        ),
      );
      final target = find.byKey(const ValueKey('paragraphTarget'));
      expect(
        find.descendant(of: target, matching: find.text('Beta')),
        findsOneWidget,
      );
      expect(find.text('Which answer is correct?'), findsNothing);
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.tap(find.byTooltip('Move to Target'));
      await tester.pump();
      expect(answer, [1, 0]);
      await tester.tap(find.byTooltip('Move up'));
      await tester.pump();
      expect(answer, [0, 1]);
      expect(tester.takeException(), isNull);
    },
  );
}
