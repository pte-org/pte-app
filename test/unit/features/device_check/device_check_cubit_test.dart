import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/device_check/constants/device_check_strings.dart';
import 'package:pte_app/features/device_check/domain/device_check_audio_player.dart';
import 'package:pte_app/features/device_check/presentation/cubit/device_check_cubit.dart';
import 'package:pte_app/features/device_check/presentation/cubit/device_check_state.dart';

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

class _MockDeviceCheckAudioPlayer extends Mock
    implements DeviceCheckAudioPlayer {}

void main() {
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
  });

  tearDown(() => playbackController.close());

  DeviceCheckCubit buildCubit() => DeviceCheckCubit(
    recorder: recorder,
    player: player,
    resolveRecordingFilePath: () async => '/tmp/device_check_test.wav',
  );

  group('DeviceCheckCubit — mic sub-flow', () {
    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'startMicRecording starts the recorder and emits recording',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) => cubit.startMicRecording(),
      expect: () => [const DeviceCheckState(micPhase: MicCheckPhase.recording)],
      verify: (_) =>
          verify(() => recorder.start('/tmp/device_check_test.wav')).called(1),
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'startMicRecording stays idle if the recorder throws (e.g. permission denied)',
      setUp: () => when(
        () => recorder.start(any()),
      ).thenThrow(Exception('permission denied')),
      build: buildCubit,
      act: (cubit) => cubit.startMicRecording(),
      expect: () => [
        const DeviceCheckState(
          micPhase: MicCheckPhase.idle,
          micErrorMessage: DeviceCheckStrings.microphoneCheckFailedMessage,
        ),
      ],
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'shows a device error without entering recording when no input device exists',
      setUp: () => when(
        () => recorder.start(any()),
      ).thenThrow(const AudioInputUnavailableException()),
      build: buildCubit,
      act: (cubit) => cubit.startMicRecording(),
      expect: () => [
        const DeviceCheckState(
          micPhase: MicCheckPhase.idle,
          micErrorMessage: DeviceCheckStrings.microphoneUnavailableMessage,
        ),
      ],
      verify: (_) => verifyNever(() => recorder.stop()),
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'stopMicRecording with a real file path emits recorded',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav'),
      build: buildCubit,
      act: (cubit) => cubit.stopMicRecording(),
      expect: () => [const DeviceCheckState(micPhase: MicCheckPhase.recorded)],
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'stopMicRecording with a null path (nothing recorded) stays idle',
      setUp: () => when(() => recorder.stop()).thenAnswer((_) async => null),
      build: buildCubit,
      act: (cubit) => cubit.stopMicRecording(),
      expect: () => [const DeviceCheckState(micPhase: MicCheckPhase.idle)],
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'playMicRecording plays the recorded file and, once playback finishes, emits playedBack',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav'),
      build: buildCubit,
      act: (cubit) async {
        await cubit.stopMicRecording();
        await cubit.playMicRecording();
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const DeviceCheckState(micPhase: MicCheckPhase.recorded),
        const DeviceCheckState(micPhase: MicCheckPhase.playingBack),
        const DeviceCheckState(micPhase: MicCheckPhase.playedBack),
      ],
      verify: (_) =>
          verify(() => player.playFile('/tmp/device_check_test.wav')).called(1),
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'playMicRecording is a no-op when nothing has been recorded yet',
      build: buildCubit,
      act: (cubit) => cubit.playMicRecording(),
      expect: () => <DeviceCheckState>[],
      verify: (_) => verifyNever(() => player.playFile(any())),
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'confirmMicHeard(true) locks in a Yes answer without changing phase',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav'),
      build: buildCubit,
      act: (cubit) async {
        await cubit.stopMicRecording();
        await cubit.playMicRecording();
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
        cubit.confirmMicHeard(true);
      },
      skip: 3,
      expect: () => [
        const DeviceCheckState(
          micPhase: MicCheckPhase.playedBack,
          micConfirmedHeardClearly: true,
        ),
      ],
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'confirmMicHeard(false) resets the mic sub-flow back to idle',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav'),
      build: buildCubit,
      act: (cubit) async {
        await cubit.stopMicRecording();
        await cubit.playMicRecording();
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
        cubit.confirmMicHeard(false);
      },
      skip: 3,
      expect: () => [const DeviceCheckState()],
    );
  });

  group('DeviceCheckCubit — sound sub-flow', () {
    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'playTestSound plays the bundled asset and, once playback finishes, emits played',
      build: buildCubit,
      act: (cubit) async {
        await cubit.playTestSound();
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const DeviceCheckState(soundPhase: SoundCheckPhase.playing),
        const DeviceCheckState(soundPhase: SoundCheckPhase.played),
      ],
      verify: (_) => verify(
        () => player.playAsset(deviceCheckTestSoundAssetPath),
      ).called(1),
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'confirmSoundHeard(true) locks in a Yes answer without changing phase',
      build: buildCubit,
      act: (cubit) async {
        await cubit.playTestSound();
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
        cubit.confirmSoundHeard(true);
      },
      skip: 2,
      expect: () => [
        const DeviceCheckState(
          soundPhase: SoundCheckPhase.played,
          soundConfirmedHeardClearly: true,
        ),
      ],
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'confirmSoundHeard(false) resets the sound sub-flow back to idle',
      build: buildCubit,
      act: (cubit) async {
        await cubit.playTestSound();
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
        cubit.confirmSoundHeard(false);
      },
      skip: 2,
      expect: () => [const DeviceCheckState()],
    );
  });

  group('DeviceCheckCubit — sub-flow independence', () {
    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'confirming/resetting the mic sub-flow never touches the sound sub-flow, and vice versa',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav'),
      build: buildCubit,
      act: (cubit) async {
        // Bring the sound sub-flow to a confirmed "Yes" state first.
        await cubit.playTestSound();
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
        cubit.confirmSoundHeard(true);
        // Now drive the mic sub-flow through its own full cycle, including
        // a "No" reset — the sound sub-flow's confirmed answer must survive
        // untouched throughout.
        await cubit.stopMicRecording();
        await cubit.playMicRecording();
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
        cubit.confirmMicHeard(false);
      },
      verify: (cubit) {
        // Final state: mic reset to idle, sound still confirmed true.
        expect(cubit.state.micPhase, MicCheckPhase.idle);
        expect(cubit.state.micConfirmedHeardClearly, isNull);
        expect(cubit.state.soundPhase, SoundCheckPhase.played);
        expect(cubit.state.soundConfirmedHeardClearly, isTrue);
      },
    );

    blocTest<DeviceCheckCubit, DeviceCheckState>(
      'playing one sub-flow while the other is already mid-playback is ignored — the interrupted sub-flow '
      'must not get permanently stuck (code-reviewer HIGH finding regression test)',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/device_check_test.wav'),
      build: buildCubit,
      act: (cubit) async {
        await cubit.stopMicRecording();
        // Start mic playback but never signal its completion yet.
        await cubit.playMicRecording();
        // Attempting to start the sound sub-flow's playback while mic
        // playback is still in flight must be a no-op — it must NOT call
        // player.playAsset, must NOT overwrite _nowPlaying, and must NOT
        // emit any sound-sub-flow state change.
        await cubit.playTestSound();
        // Now let the (still in-flight) mic playback finish — it must
        // still correctly reach playedBack, proving it was never silently
        // dropped/overwritten by the ignored sound-playback attempt.
        playbackController.add(true);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const DeviceCheckState(micPhase: MicCheckPhase.recorded),
        const DeviceCheckState(micPhase: MicCheckPhase.playingBack),
        const DeviceCheckState(micPhase: MicCheckPhase.playedBack),
      ],
      verify: (_) {
        verify(() => player.playFile('/tmp/device_check_test.wav')).called(1);
        verifyNever(() => player.playAsset(any()));
      },
    );
  });
}
