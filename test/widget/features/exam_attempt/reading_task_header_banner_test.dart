import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/reading_task_header_banner.dart';

void main() {
  testWidgets('renders the given title text and a star icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ReadingTaskHeaderBanner(title: 'Reading: Multiple Choice'))),
    );

    expect(find.text('Reading: Multiple Choice'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
