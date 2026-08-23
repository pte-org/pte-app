import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_state.dart';

/// Resolves the local temp-file path a recording for `(attemptPublicId,
/// pinnedItemPublicId)` is written to — deterministic per key so a
/// restart can locate the same file (phase-06 Design Constraints).
Future<String> resolveReadAloudFilePath(String attemptPublicId, String pinnedItemPublicId) async {
  final dir = await getTemporaryDirectory();
  return p.join(dir.path, '${attemptPublicId}_$pinnedItemPublicId.wav');
}

/// Owns start/stop recording and observes the resulting
/// `PendingMediaUploadTable` row's progress through
/// [MediaUploadCoordinator]'s pipeline. Never calls `SyncEngine.flushOne`
/// itself — that stays the advance button's job once [ReadAloudState.uploadStatus]
/// reaches [PendingMediaUploadStatus.ready] (phase-06 Design Constraints).
class ReadAloudCubit extends Cubit<ReadAloudState> {
  ReadAloudCubit({
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
       super(const ReadAloudState()) {
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
      // wasn't one already (matches the pre-refactor boolean behavior:
      // `hasRecorded` was left untouched here).
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
