import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/read_aloud_passage_panel.dart';

void main() {
  Future<void> pumpPanel(WidgetTester tester, {required String promptText, required int responseSeconds}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: ReadAloudPassagePanel(promptText: promptText, responseSeconds: responseSeconds),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the prompt text', (tester) async {
    await pumpPanel(tester, promptText: 'The quick brown fox jumps.', responseSeconds: 40);

    expect(find.text('The quick brown fox jumps.'), findsOneWidget);
  });

  testWidgets('instruction text reflects the task\'s actual responseSeconds, not a hardcoded value', (tester) async {
    await pumpPanel(tester, promptText: 'Passage A', responseSeconds: 40);
    expect(
      find.text(
        'Look at the text below. In 40 seconds, you must read this text aloud as naturally and clearly as '
        'possible. You have 40 seconds to read aloud.',
      ),
      findsOneWidget,
    );

    await pumpPanel(tester, promptText: 'Passage B', responseSeconds: 35);
    expect(
      find.text(
        'Look at the text below. In 35 seconds, you must read this text aloud as naturally and clearly as '
        'possible. You have 35 seconds to read aloud.',
      ),
      findsOneWidget,
    );
  });
}
