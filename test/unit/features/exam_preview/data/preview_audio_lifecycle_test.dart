import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';
import 'package:pte_app/features/exam_preview/data/preview_playback_state.dart';

class _Player extends Mock
    implements
        AudioPlayerService,
        PreviewPlaybackControls,
        PlaybackFailureSource {}

class _Recorder extends Mock implements AudioRecorderService {}

_Player _createPlayer(Stream<Object> failures) {
  final player = _Player();
  when(() => player.position).thenAnswer((_) => const Stream.empty());
  when(() => player.duration).thenAnswer((_) => const Stream.empty());
  when(() => player.hasFinishedPlaying).thenAnswer((_) => const Stream.empty());
  when(() => player.playbackFailures).thenAnswer((_) => failures);
  when(() => player.playUrl(any())).thenAnswer((_) async {});
  when(() => player.pausePlayback()).thenAnswer((_) async {});
  when(() => player.resumePlayback()).thenAnswer((_) async {});
  when(() => player.close()).thenAnswer((_) async {});
  return player;
}

void main() {
  for (final stopFirst in [true, false]) {
    test(
      'delayed close overlapping dispose and stop (stop first: $stopFirst)',
      () async {
        final player = _createPlayer(const Stream.empty());
        final closeStarted = Completer<void>();
        final allowClose = Completer<void>();
        when(() => player.close()).thenAnswer((_) async {
          closeStarted.complete();
          await allowClose.future;
        });
        var replacements = 0;
        final session = PreviewAudioSession(
          player: player,
          recorder: _Recorder(),
          playerFactory: () {
            replacements++;
            return _createPlayer(const Stream.empty());
          },
        );
        addTearDown(() async {
          if (!allowClose.isCompleted) allowClose.complete();
          await session.dispose();
        });
        var notifications = 0;
        session.playback.addListener(() => notifications++);
        await session.play('https://media.test/prompt.wav');
        final initialNotifications = notifications;
        final first = stopFirst ? session.stopPlayback() : session.dispose();
        await closeStarted.future;
        var bothFinished = false;
        final second = stopFirst ? session.dispose() : session.stopPlayback();
        final both = Future.wait([first, second]).then((_) {
          bothFinished = true;
        });
        await Future<void>.delayed(Duration.zero);
        expect(bothFinished, isFalse);
        allowClose.complete();
        await both;
        expect(replacements, 0);
        expect(notifications, initialNotifications);
        verify(() => player.close()).called(1);
        expect(() => session.playback.addListener(() {}), throwsFlutterError);
        await session.stopPlayback();
        await session.play('https://media.test/after-dispose.wav');
        expect(replacements, 0);
        verifyNever(
          () => player.playUrl('https://media.test/after-dispose.wav'),
        );
      },
    );
  }

  for (final resume in [false, true]) {
    test(
      'async failure after ${resume ? 'resume' : 'play'} marks failed',
      () async {
        final failures = StreamController<Object>.broadcast();
        final player = _createPlayer(failures.stream);
        final session = PreviewAudioSession(
          player: player,
          recorder: _Recorder(),
        );
        addTearDown(() async {
          await session.dispose();
          await failures.close();
        });
        await session.play('https://media.test/prompt.wav');
        if (resume) {
          await session.togglePlaybackPause();
          expect(session.playback.value.phase, PreviewPlaybackPhase.paused);
          await session.togglePlaybackPause();
          verify(() => player.resumePlayback()).called(1);
        }
        expect(session.playback.value.phase, PreviewPlaybackPhase.playing);
        failures.add(StateError('native playback rejected'));
        await Future<void>.delayed(Duration.zero);
        expect(session.playback.value.phase, PreviewPlaybackPhase.failed);
      },
    );
  }

  test(
    'replacement cancels old failure source and subscribes to new one',
    () async {
      final firstFailures = StreamController<Object>.broadcast();
      final secondFailures = StreamController<Object>.broadcast();
      final first = _createPlayer(firstFailures.stream);
      final second = _createPlayer(secondFailures.stream);
      final session = PreviewAudioSession(
        player: first,
        recorder: _Recorder(),
        playerFactory: () => second,
      );
      addTearDown(() async {
        await session.dispose();
        await firstFailures.close();
        await secondFailures.close();
      });
      expect(firstFailures.hasListener, isTrue);
      await session.play('https://media.test/first.wav');
      await session.stopPlayback();
      expect(firstFailures.hasListener, isFalse);
      expect(secondFailures.hasListener, isTrue);
      await session.play('https://media.test/second.wav');
      firstFailures.add(StateError('stale failure'));
      await Future<void>.delayed(Duration.zero);
      expect(session.playback.value.phase, PreviewPlaybackPhase.playing);
      secondFailures.add(StateError('current failure'));
      await Future<void>.delayed(Duration.zero);
      expect(session.playback.value.phase, PreviewPlaybackPhase.failed);
      await session.dispose();
      expect(secondFailures.hasListener, isFalse);
      secondFailures.add(StateError('late failure after disposal'));
      await Future<void>.delayed(Duration.zero);
    },
  );
}
