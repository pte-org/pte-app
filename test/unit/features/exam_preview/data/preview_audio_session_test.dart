import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';

class _FakePlayer implements AudioPlayerService {
  final StreamController<Duration> positions = StreamController.broadcast();
  final StreamController<Duration?> durations = StreamController.broadcast();
  final StreamController<bool> finished = StreamController.broadcast();
  String? playedUrl;
  bool closed = false;

  @override
  Stream<Duration> get position => positions.stream;

  @override
  Stream<Duration?> get duration => durations.stream;

  @override
  Stream<bool> get hasFinishedPlaying => finished.stream;

  @override
  Future<void> play(String source) async {}

  @override
  Future<void> playUrl(String url) async => playedUrl = url;

  @override
  Future<void> close() async {
    closed = true;
    await positions.close();
    await durations.close();
    await finished.close();
  }
}

class _FakeRecorder implements AudioRecorderService {
  String? currentPath;
  bool recording = false;

  @override
  Stream<double> get inputLevels => const Stream<double>.empty();

  @override
  Future<bool> isRecording() async => recording;

  @override
  Future<void> start(String filePath) async {
    currentPath = filePath;
    recording = true;
    await File(filePath).writeAsString('temporary preview audio');
  }

  @override
  Future<String?> stop() async {
    recording = false;
    return currentPath;
  }
}

void main() {
  test(
    'preview recording is temporary and is deleted before stop returns',
    () async {
      final root = await Directory.systemTemp.createTemp('pte-preview-test-');
      final player = _FakePlayer();
      final recorder = _FakeRecorder();
      final session = PreviewAudioSession(
        player: player,
        recorder: recorder,
        rootDirectory: root,
      );

      await session.startRecording();
      final path = recorder.currentPath!;
      expect(await File(path).exists(), isTrue);
      await session.stopRecording();

      expect(await File(path).exists(), isFalse);
      await session.dispose();
      expect(player.closed, isTrue);
      await root.delete(recursive: true);
    },
  );

  test(
    'audio playback uses the signed URL without a write-side dependency',
    () async {
      final root = await Directory.systemTemp.createTemp('pte-preview-test-');
      final player = _FakePlayer();
      final session = PreviewAudioSession(
        player: player,
        recorder: _FakeRecorder(),
        rootDirectory: root,
      );

      await session.play('https://media.test/signed.wav');

      expect(player.playedUrl, 'https://media.test/signed.wav');
      await session.dispose();
      await root.delete(recursive: true);
    },
  );

  test('crash cleanup removes only the preview-owned temporary root', () async {
    final root = await Directory.systemTemp.createTemp('pte-preview-test-');
    final previewRoot = Directory(
      '${root.path}${Platform.pathSeparator}pte-host-preview',
    );
    final orphan = Directory(
      '${previewRoot.path}${Platform.pathSeparator}orphan-session',
    )..createSync(recursive: true);
    final studentFile = File(
      '${root.path}${Platform.pathSeparator}student-queue.db',
    )..writeAsStringSync('must remain');

    await PreviewAudioSession.cleanupOrphans(rootDirectory: root);

    expect(await orphan.exists(), isFalse);
    expect(await studentFile.exists(), isTrue);
    await root.delete(recursive: true);
  });
}
