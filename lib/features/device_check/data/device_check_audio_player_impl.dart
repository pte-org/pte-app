import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pte_app/features/device_check/domain/device_check_audio_player.dart';

/// `just_audio`-backed impl.
///
/// [playAsset] extracts the Flutter asset to a temp file before playback
/// because `just_audio_media_kit` (the Windows backend) does not support
/// `setAsset()` — only `setFilePath` and `setUrl` work reliably via libmpv.
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
    await _player.setUrl(Uri.file(filePath).toString());
    await _player.play();
  }

  @override
  Future<void> playAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, p.basename(assetPath)));
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());
    await _player.setUrl(Uri.file(tempFile.path).toString());
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
