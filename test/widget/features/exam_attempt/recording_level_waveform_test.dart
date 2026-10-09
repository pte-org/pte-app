import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/recording_level_waveform.dart';

void main() {
  group('normalizeInputLevel', () {
    test('maps the -60 dBFS floor to 0 and -20 dBFS to 1, linear in dB', () {
      expect(normalizeInputLevel(-60), 0.0);
      expect(normalizeInputLevel(-40), 0.5);
      expect(normalizeInputLevel(-20), 1.0);
    });

    test('clamps out-of-range and non-finite levels', () {
      expect(normalizeInputLevel(-160), 0.0);
      expect(normalizeInputLevel(double.negativeInfinity), 0.0);
      expect(normalizeInputLevel(double.nan), 0.0);
      expect(normalizeInputLevel(0), 1.0);
    });
  });

  testWidgets('listens to the level stream only while mounted', (tester) async {
    final levels = StreamController<double>.broadcast();
    addTearDown(levels.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RecordingLevelWaveform(levels: levels.stream)),
      ),
    );
    expect(levels.hasListener, isTrue);

    levels
      ..add(-20)
      ..add(-50);
    await tester.pump();
    expect(find.byType(RecordingLevelWaveform), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(levels.hasListener, isFalse);
  });
}
