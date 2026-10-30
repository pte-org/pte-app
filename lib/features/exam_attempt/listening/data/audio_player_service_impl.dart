import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';

/// `just_audio`-backed impl. [play]'s `source` is a Flutter asset path (e.g.
/// `'assets/audio/listening_sample_dictation.wav'`) for the mock-data
/// phase (phase-01 Design Constraints: the asset-vs-remote distinction
/// stays inside this file, never leaks to callers). [playUrl]'s `url` is a
/// real network URL, added for Speaking's audio-prompt playback
/// (plans/phat-speaking-audio-prompt-e2e) — both share the same underlying
/// `AudioPlayer` instance since a screen only ever plays one or the other.
class AudioPlayerServiceImpl
    implements
        AudioPlayerService,
        PreviewPlaybackControls,
        PreviewPlaybackReplayControls,
        PlaybackFailureSource {
  AudioPlayerServiceImpl({AudioPlayer? player, VolumeService? volumeService})
    : _player = player ?? AudioPlayer(),
      _volumeService = volumeService {
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _hasFinishedPlayingController.add(true);
      }
    });
    final vs = _volumeService;
    if (vs != null) {
      _player.setVolume(vs.value);
      vs.addListener(_syncVolume);
    }
  }

  final AudioPlayer _player;
  final _playbackFailures = StreamController<Object>.broadcast();
  bool _closed = false;

  @override
  Stream<Object> get playbackFailures => _playbackFailures.stream;

  void _startPlayback() {
    if (_closed) return;
    unawaited(
      _player.play().catchError((Object error, StackTrace stack) {
        if (!_closed) _playbackFailures.add(error);
      }),
    );
  }

  final VolumeService? _volumeService;
  late final StreamSubscription<PlayerState> _stateSubscription;
  final StreamController<bool> _hasFinishedPlayingController =
      StreamController<bool>.broadcast();

  void _syncVolume() {
    final vs = _volumeService;
    if (vs != null) _player.setVolume(vs.value);
  }

  @override
  Future<void> play(String source) async {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      await _player.setUrl(source);
    } else {
      await _player.setAsset(source);
    }
    _startPlayback();
  }

  @override
  Future<void> playUrl(String url) async {
    await _player.setUrl(url);
    _startPlayback();
  }

  @override
  Future<void> pausePlayback() => _player.pause();

  @override
  Future<void> resumePlayback() async {
    _startPlayback();
  }

  @override
  Future<void> stopPlayback() => _player.stop();

  @override
  Future<void> replayPlayback() async {
    if (_closed) return;
    await _player.seek(Duration.zero);
    _startPlayback();
  }

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<Duration?> get duration => _player.durationStream;

  @override
  Stream<bool> get hasFinishedPlaying => _hasFinishedPlayingController.stream;

  @override
  Future<void> close() async {
    _closed = true;
    _volumeService?.removeListener(_syncVolume);
    await _stateSubscription.cancel();
    await _hasFinishedPlayingController.close();
    await _player.dispose();
    await _playbackFailures.close();
  }
}
