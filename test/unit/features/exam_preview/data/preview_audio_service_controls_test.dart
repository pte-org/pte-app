import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:pte_app/features/exam_attempt/listening/data/audio_player_service_impl.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/data/audio_recorder_service_impl.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';

class _Player extends Mock implements AudioPlayer {}

class _Recorder extends Mock implements AudioRecorder {}

void main() {
  test(
    'host replay seeks to the beginning before starting loaded audio',
    () async {
      final player = _Player();
      when(
        () => player.playerStateStream,
      ).thenAnswer((_) => const Stream.empty());
      when(() => player.seek(Duration.zero)).thenAnswer((_) async {});
      when(() => player.play()).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      final service = AudioPlayerServiceImpl(player: player);
      addTearDown(service.close);
      await service.replayPlayback();
      verifyInOrder([() => player.seek(Duration.zero), () => player.play()]);
      verifyNever(() => player.setUrl(any()));
    },
  );

  for (final action in ['playUrl', 'play', 'resume']) {
    test(
      '$action reports rejected native playback without uncaught errors',
      () async {
        final player = _Player();
        final nativePlayback = Completer<void>();
        final failure = StateError('native playback rejected');
        when(
          () => player.playerStateStream,
        ).thenAnswer((_) => const Stream.empty());
        when(() => player.setUrl(any())).thenAnswer((_) async => null);
        when(() => player.setAsset(any())).thenAnswer((_) async => null);
        when(() => player.play()).thenAnswer((_) => nativePlayback.future);
        when(() => player.dispose()).thenAnswer((_) async {});
        final service = AudioPlayerServiceImpl(player: player);
        addTearDown(service.close);
        final PlaybackFailureSource source = service;
        final reportedFailure = expectLater(
          source.playbackFailures,
          emits(same(failure)),
        );
        switch (action) {
          case 'playUrl':
            await service.playUrl('https://media.test/prompt.wav');
          case 'play':
            await service.play('assets/audio/prompt.wav');
          case 'resume':
            await service.resumePlayback();
        }
        expect(nativePlayback.isCompleted, isFalse);
        nativePlayback.completeError(failure);
        await reportedFailure.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(Duration.zero);
        verify(() => player.play()).called(1);
      },
    );
  }

  test(
    'late native rejection after close is handled without a stream write',
    () async {
      final player = _Player();
      final nativePlayback = Completer<void>();
      when(
        () => player.playerStateStream,
      ).thenAnswer((_) => const Stream.empty());
      when(() => player.play()).thenAnswer((_) => nativePlayback.future);
      when(() => player.dispose()).thenAnswer((_) async {});
      final service = AudioPlayerServiceImpl(player: player);
      final failures = <Object>[];
      final subscription = service.playbackFailures.listen(failures.add);
      addTearDown(subscription.cancel);
      await service.resumePlayback();
      await service.close();
      nativePlayback.completeError(StateError('late native rejection'));
      await Future<void>.delayed(Duration.zero);
      expect(failures, isEmpty);
    },
  );

  test('playback controls delegate to the injected audio player', () async {
    final player = _Player();
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    final service = AudioPlayerServiceImpl(player: player);
    addTearDown(service.close);
    final PreviewPlaybackControls controls = service;
    await controls.pausePlayback();
    await controls.resumePlayback();
    await controls.stopPlayback();
    verifyInOrder([
      () => player.pause(),
      () => player.play(),
      () => player.stop(),
    ]);
  });

  test('resume returns while native playback is still in progress', () async {
    final player = _Player();
    final finished = Completer<void>();
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => player.play()).thenAnswer((_) => finished.future);
    when(() => player.dispose()).thenAnswer((_) async {});
    final service = AudioPlayerServiceImpl(player: player);
    addTearDown(() async {
      finished.complete();
      await service.close();
    });
    await service.resumePlayback().timeout(const Duration(seconds: 1));
    expect(finished.isCompleted, isFalse);
    verify(() => player.play()).called(1);
  });

  test('recording controls delegate to the injected recorder', () async {
    final recorder = _Recorder();
    when(() => recorder.pause()).thenAnswer((_) async {});
    when(() => recorder.resume()).thenAnswer((_) async {});
    final PreviewRecordingControls controls = AudioRecorderServiceImpl(
      recorder: recorder,
    );
    await controls.pauseRecording();
    await controls.resumeRecording();
    verifyInOrder([() => recorder.pause(), () => recorder.resume()]);
    verifyNoMoreInteractions(recorder);
  });
}
