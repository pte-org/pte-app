import 'package:equatable/equatable.dart';

import '../../../../core/storage/pending_media_upload_status.dart';
import 'recording_phase.dart';
import 'upload_tracking_state.dart';

export 'recording_phase.dart';

/// Shared by every auto-record speaking task's screen (Read Aloud, Repeat
/// Sentence, Describe Image) — a single state shape for [AutoRecordCubit],
/// since none of these tasks' recording mechanics differ.
class AutoRecordState extends Equatable implements UploadTrackingState {
  const AutoRecordState({this.recordingPhase = RecordingPhase.idle, this.uploadStatus});

  final RecordingPhase recordingPhase;

  /// Mirrors `PendingMediaUploadTable`'s row for this task, kept live via
  /// `PendingMediaUploadDao.watchRow` — `null` until a row exists.
  @override
  final PendingMediaUploadStatus? uploadStatus;

  AutoRecordState copyWith({RecordingPhase? recordingPhase, PendingMediaUploadStatus? uploadStatus}) {
    return AutoRecordState(
      recordingPhase: recordingPhase ?? this.recordingPhase,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  @override
  List<Object?> get props => [recordingPhase, uploadStatus];
}
