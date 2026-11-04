import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/features/device_check/data/device_check_audio_player_impl.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late _MockAudioPlayer player;
  late VolumeService volumeService;
  late StreamController<PlayerState> playerStateController;

  setUp(() {
    player = _MockAudioPlayer();
    volumeService = VolumeService();
    playerStateController = StreamController<PlayerState>.broadcast();

    when(() => player.playerStateStream).thenAnswer((_) => playerStateController.stream);
    when(() => player.setVolume(any())).thenAnswer((_) async {});
    when(() => player.setUrl(any())).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await playerStateController.close();
  });

  group('DeviceCheckAudioPlayerImpl', () {
    test('initializes volume and forwards volume changes', () async {
      volumeService.value = 0.8;
      final audioPlayer = DeviceCheckAudioPlayerImpl(
        player: player,
        volumeService: volumeService,
      );

      verify(() => player.setVolume(0.8)).called(1);

      volumeService.value = 0.5;
      verify(() => player.setVolume(0.5)).called(1);

      await audioPlayer.close();
      verify(() => player.dispose()).called(1);
    });

    test('emits true on hasFinishedPlaying when processingState is completed', () async {
      final audioPlayer = DeviceCheckAudioPlayerImpl(
        player: player,
        volumeService: volumeService,
      );

      final finishedEvents = <bool>[];
      final sub = audioPlayer.hasFinishedPlaying.listen(finishedEvents.add);

      playerStateController.add(PlayerState(false, ProcessingState.buffering));
      await Future<void>.delayed(Duration.zero);
      expect(finishedEvents, isEmpty);

      playerStateController.add(PlayerState(false, ProcessingState.completed));
      await Future<void>.delayed(Duration.zero);
      expect(finishedEvents, equals([true]));

      await sub.cancel();
      await audioPlayer.close();
    });

    test('playFile sets url and triggers play', () async {
      final audioPlayer = DeviceCheckAudioPlayerImpl(
        player: player,
        volumeService: volumeService,
      );

      await audioPlayer.playFile('C:/audio/test.wav');

      verify(() => player.setUrl(Uri.file('C:/audio/test.wav').toString())).called(1);
      verify(() => player.play()).called(1);

      await audioPlayer.close();
    });
  });
}

