import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/widgets/components/exam_textarea.dart';

void main() {
  testWidgets(
    'expanded editor starts at top left and keeps first line anchored when adding lines',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 260,
              child: ExamTextarea(
                controller: controller,
                minLines: null,
                maxLines: null,
                expands: true,
                labelText: 'Your response',
              ),
            ),
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textAlignVertical, TextAlignVertical.top);
      expect(field.textAlign, TextAlign.left);
      expect(field.textInputAction, TextInputAction.newline);
      await tester.enterText(find.byType(TextField), 'First line');
      await tester.pumpAndSettle();
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final firstCaret = editable.getLocalRectForCaret(
        const TextPosition(offset: 0),
      );
      final firstCaretOnScreen = editable.localToGlobal(firstCaret.topLeft);
      final fieldBounds = tester.getRect(find.byType(TextField));
      expect(firstCaretOnScreen.dy - fieldBounds.top, lessThan(60));
      expect(firstCaretOnScreen.dx - fieldBounds.left, lessThan(30));
      expect(firstCaret.top, lessThan(40));
      expect(firstCaret.left, lessThan(10));

      await tester.enterText(
        find.byType(TextField),
        'First line\nSecond line\nThird line',
      );
      await tester.pumpAndSettle();
      final updated = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final anchoredCaret = updated.getLocalRectForCaret(
        const TextPosition(offset: 0),
      );
      final secondCaret = updated.getLocalRectForCaret(
        const TextPosition(offset: 11),
      );
      expect(anchoredCaret.top, closeTo(firstCaret.top, 1));
      expect(
        updated.localToGlobal(anchoredCaret.topLeft).dy,
        closeTo(firstCaretOnScreen.dy, 1),
      );
      expect(secondCaret.top, greaterThan(anchoredCaret.top));
      expect(secondCaret.left, closeTo(anchoredCaret.left, 1));
      expect(tester.takeException(), isNull);
    },
  );
}
