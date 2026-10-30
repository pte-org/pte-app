import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_listening_status_card.dart';

void main() {
  testWidgets('renders the player panel, status label, and volume control', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioListeningStatusCard(
            statusLabel: 'Beginning in 6 seconds',
            progress: 0.5,
          ),
        ),
      ),
    );

    expect(find.text('Beginning in 6 seconds'), findsOneWidget);
    expect(find.byType(PteAudioPanel), findsOneWidget);
    expect(find.byType(PteAudioActivityMeter), findsOneWidget);
    expect(find.text('Audio Player'), findsOneWidget);
    expect(find.byTooltip('Volume'), findsOneWidget);
    expect(find.byTooltip('Replay audio'), findsNothing);
  });

  testWidgets(
    'renders a different status label for a different prop value — proves it is prop-driven, not hardcoded',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AudioListeningStatusCard(
              statusLabel: 'Beginning in 1 seconds',
              progress: 0.9,
            ),
          ),
        ),
      );

      expect(find.text('Beginning in 1 seconds'), findsOneWidget);
    },
  );
}
