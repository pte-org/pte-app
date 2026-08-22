import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/dao/pending_media_upload_dao.dart';
import '../../../../core/storage/pending_media_upload_status.dart';
import '../../../../core/sync/media_upload_coordinator.dart';
import '../../domain/audio_recorder_service.dart';
import '../../domain/timer_phase.dart';
import '../../domain/timer_snapshot.dart';
import 'read_aloud_cubit.dart' show resolveReadAloudFilePath;
import 'recording_phase.dart';
import 'repeat_sentence_state.dart';

/// Owns start/stop recording and observes the resulting
/// `PendingMediaUploadTable` row's progress through
/// [MediaUploadCoordinator]'s pipeline. Never calls `SyncEngine.flushOne`
/// itself — that stays `AutoAdvanceOnUploadReady`'s job once
/// [RepeatSentenceState.uploadStatus] reaches [PendingMediaUploadStatus.ready].
///
/// Mirrors `ReadAloudCubit`'s mechanics exactly (duplicated, not shared —
/// this is only the 2nd auto-record cubit, below this project's
/// 3-occurrence DRY threshold; extract a shared base/mixin if a 3rd lands,
/// e.g. Describe Image or Retell Lecture, not before).
class RepeatSentenceCubit extends Cubit<RepeatSentenceState> {
  RepeatSentenceCubit({
    required AudioRecorderService recorder,
    required PendingMediaUploadDao mediaDao,
    required MediaUploadCoordinator coordinator,
    required this.attemptPublicId,
    required this.pinnedItemPublicId,
    Future<String> Function(String attemptPublicId, String pinnedItemPublicId)? resolveFilePath,
  }) : _recorder = recorder,
       _mediaDao = mediaDao,
       _coordinator = coordinator,
       _resolveFilePath = resolveFilePath ?? resolveReadAloudFilePath,
       super(const RepeatSentenceState()) {
    _rowSubscription = _mediaDao.watchRow(attemptPublicId, pinnedItemPublicId).listen((row) {
      emit(state.copyWith(uploadStatus: row == null ? null : PendingMediaUploadStatus.values.byName(row.status)));
    });
  }

  final AudioRecorderService _recorder;
  final PendingMediaUploadDao _mediaDao;
  final MediaUploadCoordinator _coordinator;
  final String attemptPublicId;
  final String pinnedItemPublicId;
  final Future<String> Function(String attemptPublicId, String pinnedItemPublicId) _resolveFilePath;

  late final StreamSubscription<PendingMediaUpload?> _rowSubscription;

  /// In-flight guards for the auto-record path. [state.recordingPhase] only
  /// flips *after* [startRecording]/[stopRecording] have awaited real async
  /// work (path resolution + the recorder plugin), so it can't by itself stop
  /// two synchronously-delivered snapshots from both passing the phase check
  /// and double-calling the recorder. These are checked-and-set synchronously
  /// in [onTimerSnapshot] — before the first `await` can yield — and cleared
  /// on completion (success *or* failure) so a later legitimate transition
  /// isn't permanently blocked.
  bool _startInFlight = false;
  bool _stopInFlight = false;

  /// Auto-starts/auto-stops recording purely from a forwarded [TimerSnapshot]
  /// and this cubit's own [RecordingPhase] — the caller (the screen, bridging
  /// `ExamAttemptBloc`'s clock) may call this on every ~1s tick, so every
  /// branch here must be a no-op unless it's an actual first-time transition
  /// (idempotent, same guard style as [stopRecording]'s recorded-preserving
  /// check). Never derives its own deadline from `TaskView` — `TimerService`
  /// is the single authoritative clock in the app (its own doc comment says
  /// "not two independent timer mechanisms"), so this only ever reacts to
  /// what it's handed. The `prep` phase here covers the whole real-world
  /// "listening" sequence (pre-listen prep + mocked audio playback +
  /// pre-record prep, rendered as one continuous countdown — see
  /// `AudioListeningStatusCard`) — this cubit doesn't need to know about
  /// that sub-structure at all, only that `response` means "start
  /// recording now."
  ///
  /// The `remaining <= Duration.zero` stop check relies on `TimerService`'s
  /// `_nonNegative` clamp always keeping `remaining` at exactly zero (never
  /// negative) once the response phase expires — a future change to that
  /// invariant would need this guard revisited.
  void onTimerSnapshot(TimerSnapshot snapshot) {
    if (snapshot.phase != TimerPhase.response) return;
    if (state.recordingPhase == RecordingPhase.idle) {
      if (_startInFlight) return;
      _startInFlight = true;
      unawaited(startRecording().whenComplete(() => _startInFlight = false));
    } else if (state.recordingPhase == RecordingPhase.recording && snapshot.remaining <= Duration.zero) {
      if (_stopInFlight) return;
      _stopInFlight = true;
      unawaited(stopRecording().whenComplete(() => _stopInFlight = false));
    }
  }

  Future<void> startRecording() async {
    final path = await _resolveFilePath(attemptPublicId, pinnedItemPublicId);
    await _recorder.start(path);
    emit(state.copyWith(recordingPhase: RecordingPhase.recording));
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) {
      // A failed re-record attempt must not discard a prior successful
      // recording's `recorded` phase — only fall back to `idle` if there
      // wasn't one already (matches `ReadAloudCubit`'s behavior).
      if (state.recordingPhase != RecordingPhase.recorded) {
        emit(state.copyWith(recordingPhase: RecordingPhase.idle));
      }
      return;
    }
    emit(state.copyWith(recordingPhase: RecordingPhase.recorded));
    await _mediaDao.upsertRecorded(
      attemptPublicId: attemptPublicId,
      pinnedItemPublicId: pinnedItemPublicId,
      localFilePath: path,
    );
    unawaited(_coordinator.attemptUpload(attemptPublicId, pinnedItemPublicId));
  }

  @override
  Future<void> close() {
    unawaited(_rowSubscription.cancel());
    return super.close();
  }
}
