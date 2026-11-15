import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/countdown_timer.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/text_editor_toolbar.dart';

void main() {
  group('CountdownTimer', () {
    testWidgets('formats time and counts down on ticker ticks', (tester) async {
      final controller = StreamController<int>.broadcast();
      addTearDown(controller.close);

      var expired = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              totalSeconds: 3,
              ticker: (_) => controller.stream,
              onExpired: () => expired = true,
            ),
          ),
        ),
      );

      expect(find.text('Time Remaining 00:03'), findsOneWidget);

      Future<void> tick(int val) async {
        controller.add(val);
        await tester.pump();
        await tester.pump();
      }

      await tick(0);
      expect(find.text('Time Remaining 00:02'), findsOneWidget);
      expect(expired, isFalse);

      await tick(1);
      expect(find.text('Time Remaining 00:01'), findsOneWidget);
      expect(expired, isFalse);

      await tick(2);
      expect(find.text('Time Remaining 00:00'), findsOneWidget);
      expect(expired, isTrue);
    });

    testWidgets('updates timer when totalSeconds changes via didUpdateWidget', (tester) async {
      final controller = StreamController<int>.broadcast();
      addTearDown(controller.close);

      var total = 30;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    CountdownTimer(
                      totalSeconds: total,
                      ticker: (_) => controller.stream,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => total = 90),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Time Remaining 00:30'), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pump();

      expect(find.text('Time Remaining 01:30'), findsOneWidget);
    });

    testWidgets('zero totalSeconds triggers onExpired immediately', (tester) async {
      var expired = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              totalSeconds: 0,
              onExpired: () => expired = true,
            ),
          ),
        ),
      );

      await tester.pump(Duration.zero);
      expect(expired, isTrue);
    });
  });

  group('TextEditorToolbar didUpdateWidget', () {
    testWidgets('swapping controller detaches old and attaches new', (tester) async {
      final controller1 = TextEditingController(text: 'first');
      final controller2 = TextEditingController(text: 'second');
      addTearDown(controller1.dispose);
      addTearDown(controller2.dispose);

      var activeController = controller1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    TextEditorToolbar(controller: activeController),
                    ElevatedButton(
                      onPressed: () => setState(() => activeController = controller2),
                      child: const Text('Switch'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Edit controller 1
      controller1.text = 'first edited';
      await tester.pump();

      // Switch to controller 2
      await tester.tap(find.text('Switch'));
      await tester.pump();

      // Editing controller 2 should now be tracked
      controller2.text = 'second edited';
      await tester.pump();

      // Undo on toolbar should restore controller 2
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(controller2.text, 'second');
    });
  });
}
