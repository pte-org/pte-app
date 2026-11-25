import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/exam_attempt/data/attempt_audio_cache.dart';
import 'package:pte_app/features/exam_attempt/listening/data/audio_player_service_impl.dart';

class _Player extends Mock implements AudioPlayer {}

class _Cache extends Mock implements AttemptAudioCache {}

const _url = 'https://cdn.test/prompt.mp3';

void main() {
  late _Player player;
  late _Cache cache;

  setUp(() {
    player = _Player();
    cache = _Cache();
    when(() => player.playerStateStream).thenAnswer((_) => const Stream.empty());
    when(() => player.setUrl(any())).thenAnswer((_) async => null);
    when(() => player.setFilePath(any())).thenAnswer((_) async => null);
    when(() => player.setAsset(any())).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
  });

  AudioPlayerServiceImpl build({AttemptAudioCache? audioCache}) {
    final service = AudioPlayerServiceImpl(player: player, audioCache: audioCache);
    addTearDown(service.close);
    return service;
  }

  test('plays the downloaded copy when one exists', () async {
    when(() => cache.localPathFor(_url)).thenReturn('/tmp/abc.mp3');

    await build(audioCache: cache).play(_url);

    verify(() => player.setFilePath('/tmp/abc.mp3')).called(1);
    verifyNever(() => player.setUrl(any()));
  });

  test('streams the url when nothing is cached', () async {
    when(() => cache.localPathFor(_url)).thenReturn(null);

    await build(audioCache: cache).play(_url);

    verify(() => player.setUrl(_url)).called(1);
    verifyNever(() => player.setFilePath(any()));
  });

  test('streams the url when there is no cache at all', () async {
    await build().play(_url);

    verify(() => player.setUrl(_url)).called(1);
  });

  test('falls back to streaming if the local copy cannot be opened', () async {
    when(() => cache.localPathFor(_url)).thenReturn('/tmp/abc.mp3');
    when(() => player.setFilePath(any())).thenThrow(StateError('bad file'));

    await build(audioCache: cache).play(_url);

    verify(() => player.setUrl(_url)).called(1);
  });

  test('bundled assets never touch the cache', () async {
    await build(audioCache: cache).play('assets/audio/prompt.wav');

    verify(() => player.setAsset('assets/audio/prompt.wav')).called(1);
    verifyNever(() => cache.localPathFor(any()));
  });
}
