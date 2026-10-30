import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart';

PreviewItem _item() => const PreviewItem(
  orderIndex: 0,
  snapshotItemPublicId: 'i',
  sourceQuestionPublicId: 'q',
  section: 'READING',
  taskType: 'FILL_IN_THE_BLANKS_DRAG_AND_DROP',
  taskTypeCode: 'FILL_IN_THE_BLANKS_DRAG_AND_DROP',
  taskTypeDisplayName: null,
  title: null,
  promptText: 'A {{1}} beginning and a {{2}} ending.',
  audioUrl: null,
  imageUrl: null,
  minWordCount: null,
  maxWordCount: null,
  options: [
    PreviewOption(orderIndex: 7, blankIndex: null, text: 'quick'),
    PreviewOption(orderIndex: 2, blankIndex: null, text: 'slow'),
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

Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [375.0, 1280.0]) {
    testWidgets(
      'host inline drag/drop, replace and undo retain identities at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Object? answer;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => HostPreviewTaskDispatcher(
                  model: PreviewTaskUiAdapter.adapt(_item()),
                  answer: answer,
                  onAnswerChanged: (next) => setState(() => answer = next),
                ),
              ),
            ),
          ),
        );
        final passage = find.byKey(const ValueKey('dragDropPassage'));
        final bank = find.byKey(const ValueKey('dragWordBank'));
        final gap0 = find.byKey(const ValueKey('dragBlank-0'));
        final gap1 = find.byKey(const ValueKey('dragBlank-1'));
        expect(
          tester.widget<Text>(passage).textSpan!.toPlainText(),
          isNot(contains('{{')),
        );
        expect(find.byType(SelectableText), findsNothing);
        expect(
          tester.getTopLeft(bank).dy,
          greaterThan(tester.getBottomLeft(passage).dy),
        );
        await _drag(tester, find.byKey(const ValueKey('dragWord-7')), gap0);
        expect(answer, {0: '7'});
        await _drag(tester, gap0, gap1);
        expect(answer, {1: '7'});
        await _drag(tester, find.byKey(const ValueKey('dragWord-2')), gap1);
        expect(answer, {1: '2'});
        expect(find.byKey(const ValueKey('dragWord-7')), findsOneWidget);
        await _drag(tester, find.byKey(const ValueKey('dragWord-7')), gap0);
        expect(answer, {0: '7', 1: '2'});
        expect(
          find.descendant(of: bank, matching: find.text('quick')),
          findsNothing,
        );
        expect(tester.getSize(bank).height, greaterThanOrEqualTo(88));
        await _drag(tester, gap1, bank);
        expect(answer, {0: '7'});
        expect(find.byKey(const ValueKey('dragWord-2')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
