import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';

/// `just_audio`-backed impl. `source` is a Flutter asset path (e.g.
/// `'assets/audio/listening_sample_dictation.wav'`) for the mock-data
/// phase — never a network URL (phase-01 Design Constraints: the asset-vs-
/// remote distinction stays inside this file, never leaks to callers).
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
  Stream<bool> get hasFinishedPlaying => _hasFinishedPlayingController.stream;

  @override
  Future<void> close() async {
    await _stateSubscription.cancel();
    await _hasFinishedPlayingController.close();
    await _player.dispose();
  }
}
