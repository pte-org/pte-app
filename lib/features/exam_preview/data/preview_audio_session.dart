import 'dart:io';

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
  }) : _player = player,
       _recorder = recorder,
       _rootDirectory = rootDirectory;

  final AudioPlayerService _player;
  final AudioRecorderService _recorder;
  final Directory? _rootDirectory;
  Directory? _sessionDirectory;
  String? _activeRecordingPath;

  Stream<Duration> get position => _player.position;
  Stream<Duration?> get duration => _player.duration;

  Future<void> play(String url) => _player.playUrl(url);

  Future<void> stopPlayback() async {
    // AudioPlayerService intentionally has no stop operation. Starting the
    // next URL replaces the current source; closing at item/session disposal
    // guarantees no player remains alive after preview exit.
  }

  Future<String> startRecording() async {
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

  Future<String?> stopRecording() async {
    final result = await _recorder.stop();
    final pathToDelete = _activeRecordingPath;
    _activeRecordingPath = null;
    if (pathToDelete != null) {
      await _deleteFile(pathToDelete);
    }
    return result;
  }

  Future<void> dispose() async {
    try {
      if (await _recorder.isRecording()) {
        await stopRecording();
      }
    } finally {
      await _player.close();
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
