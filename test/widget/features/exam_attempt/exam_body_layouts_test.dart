import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/widgets/templates/exam_template_frame.dart';
import 'package:pte_app/core/widgets/templates/exam_task_frame.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_catalog.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_task_body.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/text_editor_toolbar.dart';

void main() {
  for (final width in [1440.0, 800.0]) {
    testWidgets('all task bodies render at desktop width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final model in ExamUiPreviewCatalog.models) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExamUiPreviewTaskBody(
                key: ValueKey(model.taskType),
                model: model,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: model.taskType);
        expect(
          find.text(model.instruction),
          findsOneWidget,
          reason: model.taskType,
        );
        expect(
          find.byKey(const ValueKey('examTaskFrame')),
          findsOneWidget,
          reason: model.taskType,
        );
      }
    });
  }

  testWidgets('image/media split aligns at top and stacks on narrow screens', (
    tester,
  ) async {
    Future<void> render(double width) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExamTemplateFrame(
              title: 'Describe Image',
              instruction: 'Describe the image.',
              layout: ExamTemplateLayout.split,
              stimulus: SizedBox(height: 300, child: Text('Image')),
              response: SizedBox(height: 120, child: Text('Recorder')),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await render(1440);
    expect(
      tester.getTopLeft(find.text('Image')).dy,
      tester.getTopLeft(find.text('Recorder')).dy,
    );
    expect(
      tester.getTopLeft(find.text('Recorder')).dx,
      greaterThan(tester.getTopLeft(find.text('Image')).dx),
    );
    await render(600);
    expect(
      tester.getTopLeft(find.text('Recorder')).dy,
      greaterThan(tester.getBottomLeft(find.text('Image')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('common task frame renders the shared PTE body treatment', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExamTaskFrame(
            title: 'Read Aloud',
            instruction: 'Read the text aloud as naturally as possible.',
            body: Text('Passage'),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('examTaskFrame')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Read Aloud')).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('examTaskFrame'))).dy,
      ),
    );
    final instruction = tester.widget<Text>(
      find.text('Read the text aloud as naturally as possible.'),
    );
    expect(instruction.style?.fontStyle, FontStyle.italic);
    expect(instruction.style?.fontWeight, FontWeight.w700);

    final frame = tester.widget<Container>(
      find.byKey(const ValueKey('examTaskFrame')),
    );
    final decoration = frame.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.surface);
    expect(decoration.border, isNotNull);
  });

  testWidgets(
    'editor toolbar preserves edits across copy, paste, undo and redo',
    (tester) async {
      final controller = TextEditingController(text: 'hello');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextEditorToolbar(controller: controller),
                TextField(controller: controller),
              ],
            ),
          ),
        ),
      );
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.tap(find.byTooltip('Copy'));
      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.tap(find.byTooltip('Paste'));
      await tester.pump();
      expect(controller.text, 'hellohello');
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(controller.text, 'hello');
      await tester.tap(find.byTooltip('Redo'));
      await tester.pump();
      expect(controller.text, 'hellohello');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
