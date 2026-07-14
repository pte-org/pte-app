import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/features/speaking/presentation/pages/speaking_page.dart';
import 'package:aptis_app/features/speaking/presentation/widgets/speaking_progress_dots.dart';
import 'package:aptis_app/features/speaking/presentation/widgets/speaking_test_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _desktopTestSurfaceSize = Size(1600, 900);
const Offset _resizeDragOffset = Offset(140, 90);

void main() {
  testWidgets('SpeakingPage switches between part one and part two cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SpeakingPage()));

    expect(find.text(AppStrings.speakingPartOneLabel), findsOneWidget);
    expect(find.text(AppStrings.speakingPartOneIntro), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byType(SpeakingProgressDots),
            matching: find.byType(GestureDetector),
          )
          .at(1),
    );
    await tester.pump();

    expect(find.text(AppStrings.speakingPartTwoLabel), findsOneWidget);
    expect(find.text(AppStrings.speakingPartTwoPrompt), findsOneWidget);
  });

  testWidgets('SpeakingPage allows resizing the speaking card', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = _desktopTestSurfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SpeakingPage()));

    final initialSize = tester.getSize(find.byType(SpeakingTestCard));

    await tester.drag(find.byIcon(Icons.open_in_full), _resizeDragOffset);
    await tester.pump();

    final resizedSize = tester.getSize(find.byType(SpeakingTestCard));
    expect(resizedSize.width, greaterThan(initialSize.width));
    expect(resizedSize.height, greaterThan(initialSize.height));
  });
}
