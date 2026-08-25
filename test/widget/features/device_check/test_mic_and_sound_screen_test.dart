import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/device_check/domain/device_check_audio_player.dart';
import 'package:pte_app/features/device_check/presentation/pages/test_mic_and_sound_screen.dart';

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

class _MockDeviceCheckAudioPlayer extends Mock
    implements DeviceCheckAudioPlayer {}

/// `DeviceCheckCubit` (constructed internally by `TestMicAndSoundScreen`)
/// calls `resolveDeviceCheckRecordingFilePath`, which calls
/// `path_provider` — no platform channel handler is registered in the
/// widget-test environment by default, so `getTemporaryDirectory()` throws
/// `MissingPluginException` unless this fake is installed.
class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => '/tmp';
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  late _MockAudioRecorderService recorder;
  late _MockDeviceCheckAudioPlayer player;
  late StreamController<bool> playbackController;

  setUp(() {
    recorder = _MockAudioRecorderService();
    player = _MockDeviceCheckAudioPlayer();
    playbackController = StreamController<bool>.broadcast();
    when(
      () => player.hasFinishedPlaying,
    ).thenAnswer((_) => playbackController.stream);
    when(() => player.playFile(any())).thenAnswer((_) async {});
    when(() => player.playAsset(any())).thenAnswer((_) async {});
    when(() => player.close()).thenAnswer((_) async {});
    when(() => recorder.start(any())).thenAnswer((_) async {});
    when(() => recorder.stop()).thenAnswer((_) async => null);
  });

  tearDown(() => playbackController.close());

  Widget buildSubject() {
    return MaterialApp(
      home: TestMicAndSoundScreen(recorder: recorder, player: player),
    );
  }

  testWidgets(
    'initial render: both sections visible, Record/Play-test-sound enabled, Play-my-recording disabled',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Test your microphone'), findsOneWidget);
      expect(find.text('Test your sound'), findsOneWidget);
      expect(find.text('Record'), findsOneWidget);
      expect(find.text('Play test sound'), findsOneWidget);

      final playMyRecordingFinder = find.widgetWithText(
        ElevatedButton,
        'Play my recording',
      );
      final playMyRecordingButton = tester.widget<ElevatedButton>(
        playMyRecordingFinder,
      );
      expect(playMyRecordingButton.onPressed, isNull);
    },
  );

  testWidgets(
    'tapping Record calls recorder.start and swaps the button to Stop',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Record'));
      await tester.pump();

      verify(() => recorder.start(any())).called(1);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Record'), findsNothing);
    },
  );

  testWidgets(
    'tapping Stop calls recorder.stop and enables Play my recording',
    (tester) async {
      when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav');
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Record'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stop'));
      await tester.pump();

      verify(() => recorder.stop()).called(1);
      final playMyRecordingFinder = find.widgetWithText(
        ElevatedButton,
        'Play my recording',
      );
      final playMyRecordingButton = tester.widget<ElevatedButton>(
        playMyRecordingFinder,
      );
      expect(playMyRecordingButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'tapping Play my recording calls player.playFile with the resolved temp path',
    (tester) async {
      when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav');
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Record'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stop'));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Play my recording'),
      );
      await tester.pump();

      verify(() => player.playFile('/tmp/device_check_test.wav')).called(1);
    },
  );

  testWidgets(
    'once mic playback finishes, the confirm prompt appears; "No" resets back to Record with no confirm prompt',
    (tester) async {
      when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav');
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Record'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stop'));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Play my recording'),
      );
      await tester.pump();
      playbackController.add(true);
      await tester.pump();

      expect(find.text('Did you hear yourself clearly?'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'No'));
      await tester.pump();

      expect(find.text('Did you hear yourself clearly?'), findsNothing);
      expect(find.text('Record'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Play test sound calls player.playAsset with the bundled asset path',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Play test sound'));
      await tester.pump();

      verify(
        () => player.playAsset('assets/audio/listening_sample_dictation.wav'),
      ).called(1);
    },
  );

  testWidgets(
    'once sound playback finishes, the confirm prompt appears — mic section is unaffected by the sound sub-flow',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Play test sound'));
      await tester.pump();
      playbackController.add(true);
      await tester.pump();

      expect(find.text('Can you hear this clearly?'), findsOneWidget);
      // Mic section untouched — still shows the initial Record button, no
      // mic confirm prompt.
      expect(find.text('Record'), findsOneWidget);
      expect(find.text('Did you hear yourself clearly?'), findsNothing);
    },
  );

  testWidgets('disposing the screen closes the injected player', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    // Replace the subtree so the State's dispose() runs.
    await tester.pumpWidget(const SizedBox());

    verify(() => player.close()).called(1);
  });
}
