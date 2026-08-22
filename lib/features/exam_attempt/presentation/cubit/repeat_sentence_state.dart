import 'package:equatable/equatable.dart';

import '../../../../core/storage/pending_media_upload_status.dart';
import 'recording_phase.dart';
import 'upload_tracking_state.dart';

class RepeatSentenceState extends Equatable implements UploadTrackingState {
  const RepeatSentenceState({this.recordingPhase = RecordingPhase.idle, this.uploadStatus});

  final RecordingPhase recordingPhase;

  /// Mirrors `PendingMediaUploadTable`'s row for this task, kept live via
  /// `PendingMediaUploadDao.watchRow` — `null` until a row exists.
  @override
  final PendingMediaUploadStatus? uploadStatus;

  RepeatSentenceState copyWith({RecordingPhase? recordingPhase, PendingMediaUploadStatus? uploadStatus}) {
    return RepeatSentenceState(
      recordingPhase: recordingPhase ?? this.recordingPhase,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  @override
  List<Object?> get props => [recordingPhase, uploadStatus];
}
