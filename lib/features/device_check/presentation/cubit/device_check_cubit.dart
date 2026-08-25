import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/device_check/domain/device_check_audio_player.dart';
import 'package:pte_app/features/device_check/presentation/cubit/device_check_state.dart';

/// Fixed sound-test asset — reused from the Listening feature's existing
/// bundled samples rather than a bespoke test-tone clip (user-confirmed
/// pragmatic choice; swapping this constant is the only change needed if a
/// purpose-built clip is added later).
const String deviceCheckTestSoundAssetPath =
    'assets/audio/listening_sample_dictation.wav';

/// Fixed recording filename — named constant (matches
/// [deviceCheckTestSoundAssetPath]'s pattern) rather than an inline literal.
const String deviceCheckRecordingFileName = 'device_check_test.wav';

/// No `attemptPublicId`/`pinnedItemPublicId` context exists here — device
/// check happens before any attempt starts — so this is a fixed filename,
/// overwritten on every re-record, never uploaded/synced anywhere. Cannot
/// collide with `read_aloud_cubit.dart`'s `resolveRecordingFilePath`'s
/// `{attemptPublicId}_{pinnedItemPublicId}.wav` pattern under any realistic
/// attempt/item id.
Future<String> resolveDeviceCheckRecordingFilePath() async {
  final dir = await getTemporaryDirectory();
  return p.join(dir.path, deviceCheckRecordingFileName);
}

/// Which sub-flow's playback is currently in progress — needed because
/// [DeviceCheckAudioPlayer.hasFinishedPlaying] is one shared stream for
/// both [playFile] and [playAsset] calls; this cubit is the only thing
/// that knows which sub-flow triggered the playback currently running.
enum _NowPlaying { none, mic, sound }

/// Owns both the mic-test and sound-test sub-flows — fully independent of
/// each other (see [DeviceCheckState]'s doc comment). Not timer-driven, not
/// part of the exam-attempt machinery: every transition is a direct
/// response to a button tap.
class DeviceCheckCubit extends Cubit<DeviceCheckState> {
  DeviceCheckCubit({
    required AudioRecorderService recorder,
    required DeviceCheckAudioPlayer player,
    Future<String> Function()? resolveRecordingFilePath,
  }) : _recorder = recorder,
       _player = player,
       _resolveRecordingFilePath =
           resolveRecordingFilePath ?? resolveDeviceCheckRecordingFilePath,
       super(const DeviceCheckState()) {
    _playbackSubscription = _player.hasFinishedPlaying.listen(
      _onPlaybackFinished,
    );
  }

  final AudioRecorderService _recorder;
  final DeviceCheckAudioPlayer _player;
  final Future<String> Function() _resolveRecordingFilePath;
  late final StreamSubscription<bool> _playbackSubscription;

  String? _recordedFilePath;
  _NowPlaying _nowPlaying = _NowPlaying.none;

  Future<void> startMicRecording() async {
    try {
      final path = await _resolveRecordingFilePath();
      await _recorder.start(path);
      emit(_withMic(phase: MicCheckPhase.recording, confirmed: null));
    } catch (_) {
      // Mic permission denied or similar — stay in idle rather than
      // getting stuck showing "recording" with no way back.
      emit(_withMic(phase: MicCheckPhase.idle, confirmed: null));
    }
  }

  Future<void> stopMicRecording() async {
    final path = await _recorder.stop();
    if (path == null) {
      // "or `null` if nothing was recorded" per AudioRecorderService's own
      // doc — stay in idle rather than advancing to a phase that implies a
      // playable file exists when none does.
      emit(_withMic(phase: MicCheckPhase.idle, confirmed: null));
      return;
    }
    _recordedFilePath = path;
    emit(_withMic(phase: MicCheckPhase.recorded, confirmed: null));
  }

  Future<void> playMicRecording() async {
    final path = _recordedFilePath;
    if (path == null) return;
    // Reentrancy guard: both sub-flows share one underlying `AudioPlayer`
    // instance (see `DeviceCheckAudioPlayer`'s doc comment) — starting a
    // second playback while one is already in flight would call
    // `setFilePath`/`setAsset` mid-playback, replacing the current source
    // and silently dropping the interrupted sub-flow's completion event
    // (it would never reach `playedBack`/`played`, getting permanently
    // stuck). Ignore the tap instead; the UI also disables the other
    // section's Play button while this one is mid-playback, but the guard
    // here is the actual correctness boundary, not just a UI nicety.
    if (_nowPlaying != _NowPlaying.none) return;
    _nowPlaying = _NowPlaying.mic;
    emit(_withMic(phase: MicCheckPhase.playingBack, confirmed: null));
    await _player.playFile(path);
  }

  void confirmMicHeard(bool heard) {
    if (heard) {
      emit(_withMic(phase: state.micPhase, confirmed: true));
    } else {
      // "No" resets only the mic sub-flow back to idle so the candidate
      // can retry — the sound sub-flow is untouched.
      _recordedFilePath = null;
      emit(_withMic(phase: MicCheckPhase.idle, confirmed: null));
    }
  }

  Future<void> playTestSound() async {
    // Same reentrancy guard as `playMicRecording` — see its comment.
    if (_nowPlaying != _NowPlaying.none) return;
    _nowPlaying = _NowPlaying.sound;
    emit(_withSound(phase: SoundCheckPhase.playing, confirmed: null));
    await _player.playAsset(deviceCheckTestSoundAssetPath);
  }

  void confirmSoundHeard(bool heard) {
    if (heard) {
      emit(_withSound(phase: state.soundPhase, confirmed: true));
    } else {
      // "No" resets only the sound sub-flow — the mic sub-flow is
      // untouched.
      emit(_withSound(phase: SoundCheckPhase.idle, confirmed: null));
    }
  }

  void _onPlaybackFinished(bool finished) {
    if (!finished) return;
    switch (_nowPlaying) {
      case _NowPlaying.mic:
        emit(_withMic(phase: MicCheckPhase.playedBack, confirmed: null));
      case _NowPlaying.sound:
        emit(_withSound(phase: SoundCheckPhase.played, confirmed: null));
      case _NowPlaying.none:
        break;
    }
    _nowPlaying = _NowPlaying.none;
  }

  DeviceCheckState _withMic({
    required MicCheckPhase phase,
    required bool? confirmed,
  }) {
    return DeviceCheckState(
      micPhase: phase,
      micConfirmedHeardClearly: confirmed,
      soundPhase: state.soundPhase,
      soundConfirmedHeardClearly: state.soundConfirmedHeardClearly,
    );
  }

  DeviceCheckState _withSound({
    required SoundCheckPhase phase,
    required bool? confirmed,
  }) {
    return DeviceCheckState(
      micPhase: state.micPhase,
      micConfirmedHeardClearly: state.micConfirmedHeardClearly,
      soundPhase: phase,
      soundConfirmedHeardClearly: confirmed,
    );
  }

  @override
  Future<void> close() async {
    await _playbackSubscription.cancel();
    return super.close();
  }
}
