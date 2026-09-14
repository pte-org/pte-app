import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_task_header_banner.dart';

void main() {
  testWidgets('renders the given title text without decorative chrome', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExamTaskHeaderBanner(title: 'Reading: Multiple Choice'))),
    );

    expect(find.text('Reading: Multiple Choice'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('with no instruction given, renders only the title, no extra line', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExamTaskHeaderBanner(title: 'Reading: Multiple Choice'))),
    );

    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('renders the instruction line under the title when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExamTaskHeaderBanner(
            title: 'Reading: Multiple Choice',
            instruction: 'Select all the correct responses.',
          ),
        ),
      ),
    );

    expect(find.text('Reading: Multiple Choice'), findsOneWidget);
    expect(find.text('Select all the correct responses.'), findsOneWidget);
  });
}
