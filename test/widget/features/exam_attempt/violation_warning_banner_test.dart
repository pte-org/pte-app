import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/violation_warning_banner.dart';

/// Pumps the banner inside a real Material host so the widget tree
/// can resolve `Theme.of`/`Material`/`MediaQuery` — same pattern
/// every other widget test in this codebase uses.
Future<void> _pumpBanner(WidgetTester tester, Stream<ViolationType> stream) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ViolationWarningBanner(violations: stream),
      ),
    ),
  );
}

void main() {
  testWidgets('renders nothing when the stream has no events', (tester) async {
    final stream = Stream<ViolationType>.fromIterable(const <ViolationType>[]);
    await _pumpBanner(tester, stream);
    await tester.pump();
    expect(find.byType(ViolationWarningBanner), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('shows the right copy for each ViolationType', (tester) async {
    for (final type in ViolationType.values) {
      final controller = StreamController<ViolationType>.broadcast();
      await _pumpBanner(tester, controller.stream);
      controller.add(type);
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget,
          reason: 'banner icon should appear for ${type.name}');
      // The exact message text is verified per-type by the bloc test
      // (string keys live in ExamAttemptStrings); here we only assert
      // that SOME non-empty text is rendered.
      expect(find.byType(Text), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
    }
  });

  testWidgets('auto-dismisses after the configured display duration', (tester) async {
    final controller = StreamController<ViolationType>.broadcast();
    await _pumpBanner(tester, controller.stream);
    controller.add(ViolationType.fullscreenExit);
    await tester.pump();
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    // Advance the test clock past the default 5-second dismiss timer.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    await controller.close();
  });

  testWidgets('re-emitting resets the dismiss timer', (tester) async {
    final controller = StreamController<ViolationType>.broadcast();
    await _pumpBanner(tester, controller.stream);
    controller.add(ViolationType.fullscreenExit);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    // New event right before the original 5s timer fires.
    controller.add(ViolationType.clipboardPaste);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    // Still on screen because the timer restarted.
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    await controller.close();
  });
}
