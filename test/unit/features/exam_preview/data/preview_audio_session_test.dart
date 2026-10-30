import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';
import 'package:pte_app/features/exam_preview/data/preview_playback_state.dart';

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

class _DelayedRecorder extends _FakeRecorder {
  final started = Completer<void>();
  final allowStart = Completer<void>();

  @override
  Future<void> start(String filePath) async {
    started.complete();
    await allowStart.future;
    await super.start(filePath);
  }
}

void main() {
  test(
    'progress uses actual duration and ignores unresolved durations',
    () async {
      final player = _FakePlayer();
      final session = PreviewAudioSession(
        player: player,
        recorder: _FakeRecorder(),
      );
      addTearDown(session.dispose);
      await session.play('https://media.test/signed.wav');
      player.positions.add(const Duration(seconds: 3));
      await Future<void>.delayed(Duration.zero);
      expect(session.playback.value.progress, 0);
      player.durations.add(const Duration(seconds: 12));
      await Future<void>.delayed(Duration.zero);
      expect(session.playback.value.duration, const Duration(seconds: 12));
      expect(session.playback.value.position, const Duration(seconds: 3));
      expect(session.playback.value.progress, 0.25);
      player.durations.add(null);
      player.durations.add(Duration.zero);
      player.durations.add(const Duration(seconds: -1));
      await Future<void>.delayed(Duration.zero);
      expect(session.playback.value.duration, const Duration(seconds: 12));
      expect(session.playback.value.progress, 0.25);
    },
  );

  test('completion stays full after the player resets its position', () async {
    final player = _FakePlayer();
    final session = PreviewAudioSession(
      player: player,
      recorder: _FakeRecorder(),
    );
    addTearDown(session.dispose);
    await session.play('https://media.test/signed.wav');
    player.durations.add(const Duration(seconds: 12));
    player.positions.add(const Duration(seconds: 11));
    player.finished.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(session.playback.value.phase, PreviewPlaybackPhase.playing);
    player.finished.add(true);
    await Future<void>.delayed(Duration.zero);
    player.positions.add(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(session.playback.value.phase, PreviewPlaybackPhase.completed);
    expect(session.playback.value.position, const Duration(seconds: 12));
    expect(session.playback.value.progress, 1);
  });

  test(
    'dispose cancels every player subscription and releases notifier',
    () async {
      final player = _FakePlayer();
      final session = PreviewAudioSession(
        player: player,
        recorder: _FakeRecorder(),
      );
      expect(player.positions.hasListener, isTrue);
      expect(player.durations.hasListener, isTrue);
      expect(player.finished.hasListener, isTrue);
      await session.dispose();
      expect(player.positions.hasListener, isFalse);
      expect(player.durations.hasListener, isFalse);
      expect(player.finished.hasListener, isFalse);
      expect(player.closed, isTrue);
      expect(() => session.playback.addListener(() {}), throwsFlutterError);
    },
  );

  test(
    'Next waits for in-flight recorder start before deleting temporary media',
    () async {
      final root = await Directory.systemTemp.createTemp('pte-preview-test-');
      final recorder = _DelayedRecorder();
      final session = PreviewAudioSession(
        player: _FakePlayer(),
        recorder: recorder,
        rootDirectory: root,
      );
      final starting = session.startRecording();
      await recorder.started.future;
      final stopping = session.stopRecording();
      recorder.allowStart.complete();
      final path = await starting;
      await stopping;
      expect(recorder.recording, isFalse);
      expect(await File(path).exists(), isFalse);
      await session.dispose();
      await root.delete(recursive: true);
    },
  );
  test(
    'Next closes prior playback and the following item gets a fresh player',
    () async {
      final first = _FakePlayer();
      final second = _FakePlayer();
      final session = PreviewAudioSession(
        player: first,
        playerFactory: () => second,
        recorder: _FakeRecorder(),
      );
      await session.play('https://media.test/first.wav');
      await session.stopPlayback();
      expect(first.closed, isTrue);
      expect(first.positions.hasListener, isFalse);
      expect(first.durations.hasListener, isFalse);
      expect(first.finished.hasListener, isFalse);
      expect(session.playback.value.phase, PreviewPlaybackPhase.idle);
      await session.play('https://media.test/second.wav');
      expect(second.playedUrl, 'https://media.test/second.wav');
      second.durations.add(const Duration(seconds: 8));
      second.positions.add(const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);
      expect(session.playback.value.progress, 0.25);
      second.finished.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(session.playback.value.phase, PreviewPlaybackPhase.completed);
      await session.dispose();
      expect(second.closed, isTrue);
    },
  );
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
