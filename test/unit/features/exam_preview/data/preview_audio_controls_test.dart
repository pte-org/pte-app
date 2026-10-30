import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';
import 'package:pte_app/features/exam_preview/data/preview_playback_state.dart';

class _Player extends Mock implements AudioPlayerService {}

class _ControlledPlayer extends _Player
    implements PreviewPlaybackControls, PreviewPlaybackReplayControls {}

class _Recorder extends Mock implements AudioRecorderService {}

class _ControlledRecorder extends _Recorder
    implements PreviewRecordingControls {}

void main() {
  late _ControlledPlayer player;
  late _ControlledRecorder recorder;
  late PreviewAudioSession session;
  late Directory root;

  setUp(() async {
    player = _ControlledPlayer();
    recorder = _ControlledRecorder();
    when(() => player.position).thenAnswer((_) => const Stream.empty());
    when(() => player.duration).thenAnswer((_) => const Stream.empty());
    when(
      () => player.hasFinishedPlaying,
    ).thenAnswer((_) => const Stream.empty());
    when(() => player.playUrl(any())).thenAnswer((_) async {});
    when(() => player.close()).thenAnswer((_) async {});
    when(() => player.pausePlayback()).thenAnswer((_) async {});
    when(() => player.resumePlayback()).thenAnswer((_) async {});
    when(() => player.stopPlayback()).thenAnswer((_) async {});
    when(() => player.replayPlayback()).thenAnswer((_) async {});
    when(() => recorder.start(any())).thenAnswer((_) async {});
    when(() => recorder.stop()).thenAnswer((_) async => null);
    when(() => recorder.pauseRecording()).thenAnswer((_) async {});
    when(() => recorder.resumeRecording()).thenAnswer((_) async {});
    root = await Directory.systemTemp.createTemp('pte-preview-controls-');
    session = PreviewAudioSession(
      player: player,
      recorder: recorder,
      rootDirectory: root,
    );
  });

  tearDown(() async {
    await session.dispose();
    await root.delete(recursive: true);
  });

  test(
    'pause and resume call optional controls and notify their phases',
    () async {
      final phases = <PreviewPlaybackPhase>[];
      session.playback.addListener(
        () => phases.add(session.playback.value.phase),
      );
      expect(session.canControlPlayback, isTrue);
      await session.play('https://media.test/prompt.wav');
      await session.togglePlaybackPause();
      expect(session.playback.value.phase, PreviewPlaybackPhase.paused);
      await session.togglePlaybackPause();
      expect(session.playback.value.phase, PreviewPlaybackPhase.playing);
      expect(phases, [
        PreviewPlaybackPhase.loading,
        PreviewPlaybackPhase.playing,
        PreviewPlaybackPhase.paused,
        PreviewPlaybackPhase.playing,
      ]);
      verifyInOrder([
        () => player.pausePlayback(),
        () => player.resumePlayback(),
      ]);
    },
  );

  test('host stop publishes stopped without closing the player', () async {
    await session.play('https://media.test/prompt.wav');
    await session.stopPlaybackByHost();
    expect(session.playback.value.phase, PreviewPlaybackPhase.stopped);
    await session.togglePlaybackPause();
    expect(session.playback.value.phase, PreviewPlaybackPhase.stopped);
    verify(() => player.stopPlayback()).called(1);
    verifyNever(() => player.pausePlayback());
    verifyNever(() => player.resumePlayback());
    verifyNever(() => player.close());
  });

  for (final phase in [
    PreviewPlaybackPhase.completed,
    PreviewPlaybackPhase.stopped,
  ]) {
    test(
      'host replay from $phase resets timing and reuses loaded audio',
      () async {
        expect(session.canReplayPlayback, isFalse);
        await session.play('https://media.test/prompt.wav');
        session.playback.value = PreviewPlaybackState(
          phase: phase,
          duration: const Duration(seconds: 8),
          position: const Duration(seconds: 8),
        );
        expect(session.canReplayPlayback, isTrue);
        await session.replayPlayback();
        expect(session.playback.value.phase, PreviewPlaybackPhase.playing);
        expect(session.playback.value.position, Duration.zero);
        expect(session.playback.value.progress, 0);
        expect(session.playback.value.duration, const Duration(seconds: 8));
        verify(() => player.replayPlayback()).called(1);
        verify(() => player.playUrl(any())).called(1);
        await session.replayPlayback();
        verifyNever(() => player.replayPlayback());
        verifyNever(() => player.playUrl(any()));
      },
    );
  }

  test(
    'Next wins over pending replay and repeated clicks do not replay twice',
    () async {
      final replay = Completer<void>();
      when(() => player.replayPlayback()).thenAnswer((_) => replay.future);
      await session.play('https://media.test/prompt.wav');
      await session.stopPlaybackByHost();
      final replaying = session.replayPlayback();
      expect(session.playback.value.phase, PreviewPlaybackPhase.loading);
      await session.replayPlayback();
      await session.stopPlayback();
      replay.complete();
      await replaying;
      verify(() => player.replayPlayback()).called(1);
      expect(session.playback.value.phase, PreviewPlaybackPhase.idle);
    },
  );

  test('idle pause toggle does not call the player', () async {
    await session.togglePlaybackPause();
    expect(session.playback.value.phase, PreviewPlaybackPhase.idle);
    verifyNever(() => player.pausePlayback());
    verifyNever(() => player.resumePlayback());
  });

  test('host stop wins over an in-flight playback start', () async {
    final started = Completer<void>();
    when(() => player.playUrl(any())).thenAnswer((_) => started.future);
    final playing = session.play('https://media.test/prompt.wav');
    expect(session.playback.value.phase, PreviewPlaybackPhase.loading);
    await session.stopPlaybackByHost();
    started.complete();
    await playing;
    expect(session.playback.value.phase, PreviewPlaybackPhase.stopped);
  });

  test('late pause completion cannot replace the stopped phase', () async {
    final paused = Completer<void>();
    when(() => player.pausePlayback()).thenAnswer((_) => paused.future);
    await session.play('https://media.test/prompt.wav');
    final pausing = session.togglePlaybackPause();
    await session.stopPlaybackByHost();
    paused.complete();
    await pausing;
    expect(session.playback.value.phase, PreviewPlaybackPhase.stopped);
  });

  test(
    'recording pause and resume apply only to an active recording',
    () async {
      expect(session.canPauseRecording, isTrue);
      await session.pauseRecording();
      await session.resumeRecording();
      verifyNever(() => recorder.pauseRecording());
      verifyNever(() => recorder.resumeRecording());
      final path = await session.startRecording();
      await session.pauseRecording();
      await session.resumeRecording();
      await session.stopRecording();
      await session.pauseRecording();
      await session.resumeRecording();
      verifyInOrder([
        () => recorder.start(path),
        () => recorder.pauseRecording(),
        () => recorder.resumeRecording(),
        () => recorder.stop(),
      ]);
      verifyNoMoreInteractions(recorder);
    },
  );

  test('recording controls wait for an in-flight recorder start', () async {
    final started = Completer<void>();
    final allowStart = Completer<void>();
    when(() => recorder.start(any())).thenAnswer((_) async {
      started.complete();
      await allowStart.future;
    });
    final starting = session.startRecording();
    await started.future;
    final pausing = session.pauseRecording();
    final resuming = session.resumeRecording();
    verifyNever(() => recorder.pauseRecording());
    verifyNever(() => recorder.resumeRecording());
    allowStart.complete();
    final path = await starting;
    await pausing;
    await resuming;
    verifyInOrder([
      () => recorder.start(path),
      () => recorder.pauseRecording(),
      () => recorder.resumeRecording(),
    ]);
  });

  test('legacy services remain usable without optional controls', () async {
    final legacyPlayer = _Player();
    final legacyRecorder = _Recorder();
    when(() => legacyPlayer.position).thenAnswer((_) => const Stream.empty());
    when(() => legacyPlayer.duration).thenAnswer((_) => const Stream.empty());
    when(
      () => legacyPlayer.hasFinishedPlaying,
    ).thenAnswer((_) => const Stream.empty());
    when(() => legacyPlayer.playUrl(any())).thenAnswer((_) async {});
    when(() => legacyPlayer.close()).thenAnswer((_) async {});
    when(() => legacyRecorder.start(any())).thenAnswer((_) async {});
    when(() => legacyRecorder.stop()).thenAnswer((_) async => null);
    final legacy = PreviewAudioSession(
      player: legacyPlayer,
      recorder: legacyRecorder,
      rootDirectory: root,
    );
    addTearDown(legacy.dispose);
    expect(legacy.canControlPlayback, isFalse);
    expect(legacy.canPauseRecording, isFalse);
    await legacy.play('https://media.test/prompt.wav');
    await legacy.togglePlaybackPause();
    await legacy.stopPlaybackByHost();
    expect(legacy.playback.value.phase, PreviewPlaybackPhase.playing);
    await legacy.startRecording();
    await legacy.pauseRecording();
    await legacy.resumeRecording();
    await legacy.stopRecording();
    verify(() => legacyRecorder.stop()).called(1);
  });
}
