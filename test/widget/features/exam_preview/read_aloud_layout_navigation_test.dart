import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/widgets/exam/exam_footer_bar.dart';
import 'package:pte_app/core/widgets/templates/read_aloud_template.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_navigation.dart';

void main() {
  testWidgets('Read Aloud orders instruction, recorder, then passage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadAloudTemplate(
            title: 'Read Aloud',
            instruction: 'Read aloud.',
            recorder: SizedBox(height: 160, child: Text('Recorder')),
            passage: Text('Passage'),
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Read aloud.')).dy,
      lessThan(tester.getTopLeft(find.text('Recorder')).dy),
    );
    expect(
      tester.getBottomLeft(find.text('Recorder')).dy,
      lessThan(tester.getTopLeft(find.text('Passage')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('host uses the shared footer and Next works without an answer', (
    tester,
  ) async {
    var nextCalls = 0;
    var previousCalls = 0;
    Widget subject({bool busy = false}) => MaterialApp(
      home: Scaffold(
        bottomNavigationBar: HostPreviewNavigation(
          isBusy: busy,
          onPrevious: () => previousCalls++,
          onNext: () => nextCalls++,
        ),
      ),
    );
    await tester.pumpWidget(subject());
    expect(find.byType(ExamFooterBar), findsOneWidget);
    await tester.tap(find.text('Previous'));
    expect(previousCalls, 1);
    await tester.tap(find.text('Next'));
    expect(nextCalls, 1);
    await tester.pumpWidget(subject(busy: true));
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(nextCalls, 1);
    await tester.pumpWidget(subject());
    await tester.tap(find.text('Next'));
    expect(nextCalls, 2);
    expect(tester.takeException(), isNull);
  });
}
