import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';

/// `just_audio`-backed impl. [play]'s `source` is a Flutter asset path (e.g.
/// `'assets/audio/listening_sample_dictation.wav'`) for the mock-data
/// phase (phase-01 Design Constraints: the asset-vs-remote distinction
/// stays inside this file, never leaks to callers). [playUrl]'s `url` is a
/// real network URL, added for Speaking's audio-prompt playback
/// (plans/phat-speaking-audio-prompt-e2e) — both share the same underlying
/// `AudioPlayer` instance since a screen only ever plays one or the other.
class AudioPlayerServiceImpl implements AudioPlayerService {
  AudioPlayerServiceImpl({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _hasFinishedPlayingController.add(true);
      }
    });
  }

  final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSubscription;
  final StreamController<bool> _hasFinishedPlayingController = StreamController<bool>.broadcast();

  @override
  Future<void> play(String source) async {
    await _player.setAsset(source);
    await _player.play();
  }

  @override
  Future<void> playUrl(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<Duration?> get duration => _player.durationStream;

  @override
  Stream<bool> get hasFinishedPlaying => _hasFinishedPlayingController.stream;

  @override
  Future<void> close() async {
    await _stateSubscription.cancel();
    await _hasFinishedPlayingController.close();
    await _player.dispose();
  }
}
