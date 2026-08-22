import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/read_aloud_recording_indicator.dart';

void main() {
  testWidgets('renders elapsed/total as mm:ss / mm:ss', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadAloudRecordingIndicator(
            isRecording: true,
            elapsed: Duration(seconds: 34),
            total: Duration(seconds: 40),
          ),
        ),
      ),
    );

    expect(find.text('00:34 / 00:40'), findsOneWidget);
  });

  testWidgets('renders without animating while not recording', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadAloudRecordingIndicator(
            isRecording: false,
            elapsed: Duration.zero,
            total: Duration(seconds: 40),
          ),
        ),
      ),
    );

    expect(find.text('00:00 / 00:40'), findsOneWidget);
    // No pending frames scheduled — pumpAndSettle would time out if the
    // controllers were repeating despite isRecording: false.
    await tester.pumpAndSettle();
  });

  testWidgets(
    'toggling isRecording on an already-mounted instance (didUpdateWidget) starts/stops both '
    'AnimationControllers — the real production path when the cubit flips recording mid-frame while the '
    'indicator stays mounted, distinct from the fixed-props-at-creation cases above',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadAloudRecordingIndicator(isRecording: false, elapsed: Duration.zero, total: Duration(seconds: 40)),
          ),
        ),
      );
      // Not recording yet — no ticker scheduled.
      expect(tester.binding.transientCallbackCount, 0);

      // Same widget type/position, no key change — State persists and
      // didUpdateWidget fires rather than initState.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadAloudRecordingIndicator(isRecording: true, elapsed: Duration.zero, total: Duration(seconds: 40)),
          ),
        ),
      );
      await tester.pump();
      // Both controllers now repeating — at least one ticker scheduled.
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadAloudRecordingIndicator(isRecording: false, elapsed: Duration.zero, total: Duration(seconds: 40)),
          ),
        ),
      );
      await tester.pump();
      // Stopped again — no ticker left scheduled, and pumpAndSettle must not
      // hang (would time out if `_dotController.stop()`/`_waveController.stop()`
      // weren't actually called from didUpdateWidget).
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('disposes both AnimationControllers cleanly when removed from the tree', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadAloudRecordingIndicator(
            isRecording: true,
            elapsed: Duration(seconds: 5),
            total: Duration(seconds: 40),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Replacing the widget tree tears down the indicator's State — if
    // either AnimationController weren't disposed, flutter_test's own
    // pending-timer/ticker check fails this test automatically on teardown.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pumpAndSettle();
  });
}
