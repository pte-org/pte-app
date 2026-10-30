import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'preview_playback_state.dart';

import 'package:path/path.dart' as path;

import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';

/// Preview-owned media lifecycle. It deliberately has no answer/outbox or
/// upload dependency; recordings are temporary files under a preview-only
/// directory and are removed during [dispose].
class PreviewAudioSession {
  PreviewAudioSession({
    required AudioPlayerService player,
    required AudioRecorderService recorder,
    Directory? rootDirectory,
    AudioPlayerService Function()? playerFactory,
  }) : _player = player,
       _recorder = recorder,
       _rootDirectory = rootDirectory,
       _playerFactory = playerFactory {
    _bindPlayer();
  }

  AudioPlayerService _player;
  final AudioPlayerService Function()? _playerFactory;
  final AudioRecorderService _recorder;
  final Directory? _rootDirectory;
  Directory? _sessionDirectory;
  String? _activeRecordingPath;
  Future<void> _recordingTail = Future<void>.value();
  bool _hasPlayed = false;
  bool _playerClosed = false;
  final playback = ValueNotifier<PreviewPlaybackState>(
    const PreviewPlaybackState(),
  );
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  int _playbackEpoch = 0;
  bool _disposed = false;
  bool _playbackControlBusy = false;
  Future<void> _playerTail = Future<void>.value();

  Future<void> _serializePlayer(Future<void> Function() action) {
    final operation = _playerTail.then((_) => action());
    _playerTail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  bool get canControlPlayback => _player is PreviewPlaybackControls;
  bool get canPauseRecording => _recorder is PreviewRecordingControls;
  bool get playbackControlBusy => _playbackControlBusy;
  bool get canReplayPlayback =>
      !_disposed &&
      !_playerClosed &&
      _hasPlayed &&
      _player is PreviewPlaybackReplayControls &&
      !_playbackControlBusy &&
      (playback.value.phase == PreviewPlaybackPhase.completed ||
          playback.value.phase == PreviewPlaybackPhase.stopped);

  Future<void> replayPlayback() async {
    if (!canReplayPlayback) return;
    final player = _player as PreviewPlaybackReplayControls;
    final epoch = ++_playbackEpoch;
    _playbackControlBusy = true;
    playback.value = playback.value.copyWith(
      phase: PreviewPlaybackPhase.loading,
      position: Duration.zero,
    );
    try {
      await player.replayPlayback();
      if (!_disposed &&
          epoch == _playbackEpoch &&
          playback.value.phase == PreviewPlaybackPhase.loading) {
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.playing,
        );
      }
    } catch (_) {
      if (!_disposed && epoch == _playbackEpoch) {
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.failed,
        );
      }
    } finally {
      _playbackControlBusy = false;
    }
  }

  void _bindPlayer() {
    final player = _player;
    if (player is PlaybackFailureSource) {
      _subscriptions.add(
        (player as PlaybackFailureSource).playbackFailures.listen((_) {
          if (_disposed) return;
          playback.value = playback.value.copyWith(
            phase: PreviewPlaybackPhase.failed,
          );
        }),
      );
    }
    _subscriptions.add(
      _player.position.listen((position) {
        if (playback.value.phase == PreviewPlaybackPhase.completed) return;
        playback.value = playback.value.copyWith(position: position);
      }),
    );
    _subscriptions.add(
      _player.duration.listen((duration) {
        if (duration == null || duration <= Duration.zero) return;
        playback.value = playback.value.copyWith(duration: duration);
      }),
    );
    _subscriptions.add(
      _player.hasFinishedPlaying.listen((finished) {
        if (!finished) return;
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.completed,
          position: playback.value.duration ?? playback.value.position,
        );
      }),
    );
  }

  Future<void> _unbindPlayer() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  Stream<Duration> get position => _player.position;
  Stream<Duration?> get duration => _player.duration;
  Stream<double> get inputLevels => _recorder.inputLevels;

  Future<void> play(String url) async {
    if (_disposed || _playerClosed) return;
    final epoch = ++_playbackEpoch;
    _hasPlayed = true;
    playback.value = const PreviewPlaybackState(
      phase: PreviewPlaybackPhase.loading,
    );
    try {
      await _player.playUrl(url);
      if (epoch != _playbackEpoch) return;
      if (playback.value.phase == PreviewPlaybackPhase.loading) {
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.playing,
        );
      }
    } catch (_) {
      if (epoch == _playbackEpoch) {
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.failed,
        );
      }
      rethrow;
    }
  }

  Future<void> togglePlaybackPause() async {
    final player = _player;
    if (_disposed ||
        _playbackControlBusy ||
        player is! PreviewPlaybackControls) {
      return;
    }
    _playbackControlBusy = true;
    final epoch = _playbackEpoch;
    try {
      final phase = playback.value.phase;
      if (phase == PreviewPlaybackPhase.playing) {
        await (player as PreviewPlaybackControls).pausePlayback();
        if (epoch == _playbackEpoch && playback.value.phase == phase) {
          playback.value = playback.value.copyWith(
            phase: PreviewPlaybackPhase.paused,
          );
        }
      } else if (phase == PreviewPlaybackPhase.paused) {
        await (player as PreviewPlaybackControls).resumePlayback();
        if (epoch == _playbackEpoch && playback.value.phase == phase) {
          playback.value = playback.value.copyWith(
            phase: PreviewPlaybackPhase.playing,
          );
        }
      }
    } catch (_) {
      if (!_disposed && epoch == _playbackEpoch) {
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.failed,
        );
      }
    } finally {
      _playbackControlBusy = false;
    }
  }

  Future<void> stopPlaybackByHost() async {
    final player = _player;
    if (_disposed || player is! PreviewPlaybackControls) return;
    final epoch = ++_playbackEpoch;
    try {
      await (player as PreviewPlaybackControls).stopPlayback();
    } catch (_) {
      if (!_disposed && epoch == _playbackEpoch) {
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.failed,
        );
      }
      return;
    }
    if (_disposed || epoch != _playbackEpoch) return;
    playback.value = playback.value.copyWith(
      phase: PreviewPlaybackPhase.stopped,
    );
  }

  Future<void> pauseRecording() => _serializeRecording(() async {
    final recorder = _recorder;
    if (_activeRecordingPath != null && recorder is PreviewRecordingControls) {
      await (recorder as PreviewRecordingControls).pauseRecording();
    }
  });

  Future<void> resumeRecording() => _serializeRecording(() async {
    final recorder = _recorder;
    if (_activeRecordingPath != null && recorder is PreviewRecordingControls) {
      await (recorder as PreviewRecordingControls).resumeRecording();
    }
  });

  Future<void> stopPlayback() => _serializePlayer(() async {
    ++_playbackEpoch;
    if (!_hasPlayed || _playerClosed) return;
    await _unbindPlayer();
    await _player.close();
    _playerClosed = true;
    _hasPlayed = false;
    if (_disposed) return;
    final factory = _playerFactory;
    if (factory != null) {
      _player = factory();
      _playerClosed = false;
      _bindPlayer();
    }
    playback.value = const PreviewPlaybackState();
  });

  Future<T> _serializeRecording<T>(Future<T> Function() action) {
    final operation = _recordingTail.then((_) => action());
    _recordingTail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  Future<String> startRecording() => _serializeRecording(_startRecording);

  Future<String> _startRecording() async {
    final directory = await _ensureDirectory();
    final file = File(
      path.join(
        directory.path,
        'recording-${DateTime.now().microsecondsSinceEpoch}.wav',
      ),
    );
    _activeRecordingPath = file.path;
    await _recorder.start(file.path);
    return file.path;
  }

  Future<String?> stopRecording() => _serializeRecording(_stopRecording);

  Future<String?> _stopRecording() async {
    if (_activeRecordingPath == null) return null;
    final pathToDelete = _activeRecordingPath;
    try {
      return await _recorder.stop();
    } finally {
      _activeRecordingPath = null;
      if (pathToDelete != null) await _deleteFile(pathToDelete);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_playbackEpoch;
    await _serializePlayer(() async {
      await _unbindPlayer();
      if (!_playerClosed) await _player.close();
      _playerClosed = true;
    });
    try {
      await stopRecording();
    } finally {
      playback.dispose();
      final directory = _sessionDirectory;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  /// Removes only preview-owned temporary recordings left by an interrupted
  /// host preview process. Student attempt/media directories are never under
  /// this root and are therefore outside the sweep boundary.
  static Future<void> cleanupOrphans({Directory? rootDirectory}) async {
    final root = rootDirectory ?? Directory.systemTemp;
    final previewRoot = Directory(path.join(root.path, 'pte-host-preview'));
    if (!await previewRoot.exists()) return;
    await previewRoot.delete(recursive: true);
  }

  Future<Directory> _ensureDirectory() async {
    final existing = _sessionDirectory;
    if (existing != null) return existing;
    final root = _rootDirectory ?? Directory.systemTemp;
    final directory = Directory(
      path.join(
        root.path,
        'pte-host-preview',
        '${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await directory.create(recursive: true);
    _sessionDirectory = directory;
    return directory;
  }

  Future<void> _deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }
}
