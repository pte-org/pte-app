import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/widgets/components/playback_level_meter.dart';
import 'package:pte_app/core/widgets/components/pte_audio_level_meter.dart';

void main() {
  const channel = MethodChannel('pte/audio_levels');
  testWidgets(
    'meter follows native peaks and stops polling when paused or removed',
    (tester) async {
      var peak = 0.75;
      var samples = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expect(call.method, 'getPlaybackLevel');
        samples++;
        return peak;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      Widget subject(bool active) => MaterialApp(
        home: Scaffold(body: PlaybackLevelMeter(active: active)),
      );
      await tester.pumpWidget(subject(true));
      await tester.pump();
      expect(
        tester
            .widget<PteAudioLevelMeter>(find.byType(PteAudioLevelMeter))
            .level,
        0.75,
      );
      peak = 0;
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      expect(
        tester
            .widget<PteAudioLevelMeter>(find.byType(PteAudioLevelMeter))
            .level,
        lessThan(0.75),
      );
      await tester.pumpWidget(subject(false));
      final stoppedSamples = samples;
      await tester.pump(const Duration(seconds: 1));
      expect(samples, stoppedSamples);
      expect(
        tester
            .widget<PteAudioLevelMeter>(find.byType(PteAudioLevelMeter))
            .level,
        0,
      );
      await tester.pumpWidget(subject(true));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      final removedSamples = samples;
      await tester.pump(const Duration(seconds: 1));
      expect(samples, removedSamples);
      expect(tester.takeException(), isNull);
    },
  );
}
