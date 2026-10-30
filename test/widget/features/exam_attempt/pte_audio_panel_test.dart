import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';
import 'package:pte_app/core/constants/app_colors.dart';

void main() {
  testWidgets(
    'preparation shows a disabled red record indicator instead of Stop',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PteAudioPanel(
              variant: PteAudioPanelVariant.recorder,
              statusLabel: 'Recording in 1',
              progress: 0,
              playing: false,
              isPreparingRecording: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.stop), findsNothing);
      final recordButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.fiber_manual_record),
      );
      expect(recordButton.onPressed, isNull);
      expect(recordButton.disabledColor, AppColors.error);
    },
  );
  testWidgets('renders the shared player chrome and supplied controls', (
    tester,
  ) async {
    var primaryPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PteAudioPanel(
            variant: PteAudioPanelVariant.player,
            statusLabel: 'Playing',
            progress: 0.5,
            timeLabel: '0:22 / 1:05',
            onPrimaryAction: () => primaryPressed = true,
            showActivityMeter: true,
            trailingControl: const Icon(Icons.volume_up),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
    expect(find.text('Audio Player'), findsOneWidget);
    expect(find.text('Playing'), findsOneWidget);
    expect(find.text('0:22 / 1:05'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.byType(PteAudioActivityMeter), findsOneWidget);

    await tester.tap(find.byTooltip('Pause audio'));
    expect(primaryPressed, isTrue);
  });

  testWidgets('renders the shared recorder chrome and side meter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PteAudioPanel(
            variant: PteAudioPanelVariant.recorder,
            statusLabel: 'Recording',
            progress: 0.25,
            timeLabel: '0:10 / 0:40',
            sideIndicator: SizedBox(width: 32, height: 24),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
    expect(find.text('Audio Recorder'), findsOneWidget);
    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('0:10 / 0:40'), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
