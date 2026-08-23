import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_listening_status_card.dart';

void main() {
  testWidgets('renders the status label and the Volume row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioListeningStatusCard(statusLabel: 'Beginning in 6 seconds', progress: 0.5),
        ),
      ),
    );

    expect(find.text('Beginning in 6 seconds'), findsOneWidget);
    expect(find.text('Current Status:'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
  });

  testWidgets('renders a different status label for a different prop value — proves it is prop-driven, not hardcoded', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioListeningStatusCard(statusLabel: 'Beginning in 1 seconds', progress: 0.9),
        ),
      ),
    );

    expect(find.text('Beginning in 1 seconds'), findsOneWidget);
  });
}
