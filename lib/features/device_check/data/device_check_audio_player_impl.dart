import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:pte_app/features/device_check/domain/device_check_audio_player.dart';

/// `just_audio`-backed impl. `setFilePath`/`setAsset` are both documented
/// convenience wrappers around `setAudioSource` — safe to call repeatedly
/// on the same long-lived [AudioPlayer] instance to switch sources (the
/// standard `just_audio` track-switching pattern), so one instance covers
/// both [playFile] and [playAsset] with no leak or stale-state risk.
class DeviceCheckAudioPlayerImpl implements DeviceCheckAudioPlayer {
  DeviceCheckAudioPlayerImpl({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _hasFinishedPlayingController.add(true);
      }
    });
  }

  final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSubscription;
  final StreamController<bool> _hasFinishedPlayingController =
      StreamController<bool>.broadcast();

  @override
  Future<void> playFile(String filePath) async {
    await _player.setFilePath(filePath);
    await _player.play();
  }

  @override
  Future<void> playAsset(String assetPath) async {
    await _player.setAsset(assetPath);
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
