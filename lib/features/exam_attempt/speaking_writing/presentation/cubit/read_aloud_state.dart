import 'package:equatable/equatable.dart';

import 'package:pte_app/core/storage/pending_media_upload_status.dart';

/// The recording workflow's current phase — a single field instead of
/// separate `isRecording`/`hasRecorded` booleans, since the two states are
/// mutually exclusive (never both true at once).
enum RecordingPhase { idle, recording, recorded }

class ReadAloudState extends Equatable {
  const ReadAloudState({this.recordingPhase = RecordingPhase.idle, this.uploadStatus});

  final RecordingPhase recordingPhase;

  /// Mirrors `PendingMediaUploadTable`'s row for this task, kept live via
  /// `PendingMediaUploadDao.watchRow` — `null` until a row exists.
  final PendingMediaUploadStatus? uploadStatus;

  ReadAloudState copyWith({RecordingPhase? recordingPhase, PendingMediaUploadStatus? uploadStatus}) {
    return ReadAloudState(
      recordingPhase: recordingPhase ?? this.recordingPhase,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  @override
  List<Object?> get props => [recordingPhase, uploadStatus];
}
