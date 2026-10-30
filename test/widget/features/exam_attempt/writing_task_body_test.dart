import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/summarize_written_text_body.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/write_essay_v2_body.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/writing_task_body.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/text_editor_toolbar.dart';

void main() {
  for (final width in [375.0, 1200.0]) {
    testWidgets(
      'essay note and toolbar counter fit at $width and update after undo',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WritingResponseEditor(
                controller: controller,
                label: 'Your response',
                minWords: 200,
                maxWords: 300,
              ),
            ),
          ),
        );
        expect(
          find.text('Write at least 200 words, but no more than 300.'),
          findsOneWidget,
        );
        expect(find.text('0 / 300 Word Limit'), findsOneWidget);
        final toolbar = tester.getRect(find.byType(TextEditorToolbar));
        final counter = tester.getRect(
          find.byKey(const ValueKey('writingWordCounter')),
        );
        expect(toolbar.contains(counter.center), isTrue);
        expect(toolbar.right - counter.right, lessThanOrEqualTo(20));
        await tester.enterText(find.byType(TextField), 'One two three');
        await tester.pump();
        expect(find.text('3 / 300 Word Limit'), findsOneWidget);
        await tester.tap(find.byTooltip('Undo'));
        await tester.pump();
        expect(find.text('0 / 300 Word Limit'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final essay in [false, true]) {
    testWidgets(
      '${essay ? 'Essay' : 'Summary'} shares editor and preserves drafts',
      (tester) async {
        final drafts = <String>[];
        final task = TaskView(
          pinnedItemPublicId: 'item',
          orderIndex: 1,
          totalTasks: 2,
          section: 'WRITING',
          taskType: essay ? 'WRITE_ESSAY' : 'SUMMARIZE_WRITTEN_TEXT',
          title: 'Writing',
          promptText: 'Source passage',
          prepSeconds: 0,
          responseSeconds: 600,
          minWordCount: 1,
          maxWordCount: 75,
        );
        Widget subject() => MaterialApp(
          home: Scaffold(
            body: essay
                ? WriteEssayV2Body(
                    task: task,
                    initialAnswer: 'initial draft',
                    persistDraft: drafts.add,
                  )
                : SummarizeWrittenTextBody(
                    task: task,
                    initialAnswer: 'initial draft',
                    persistDraft: drafts.add,
                  ),
          ),
        );
        await tester.pumpWidget(subject());
        expect(find.byType(WritingResponseEditor), findsOneWidget);
        expect(find.text('Source passage'), findsOneWidget);
        expect(find.text('2 / 75 Word Limit'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(TextEditorToolbar),
            matching: find.byKey(const ValueKey('writingWordCounter')),
          ),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField), 'updated draft');
        await tester.pump();
        expect(drafts.last, 'updated draft');
        await tester.pumpWidget(subject());
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'updated draft',
        );
        await tester.enterText(find.byType(TextField), 'three word draft');
        await tester.pump();
        expect(find.text('3 / 75 Word Limit'), findsOneWidget);
        expect(drafts.last, 'three word draft');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
