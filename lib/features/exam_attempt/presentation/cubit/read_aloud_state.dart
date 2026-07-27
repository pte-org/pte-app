import 'package:equatable/equatable.dart';

import '../../../../core/storage/pending_media_upload_status.dart';

class ReadAloudState extends Equatable {
  const ReadAloudState({this.isRecording = false, this.hasRecorded = false, this.uploadStatus});

  final bool isRecording;

  /// True once `stopRecording()` has produced a local file — independent
  /// of [uploadStatus], which only exists once the outbox coordinator's
  /// row is observable.
  final bool hasRecorded;

  /// Mirrors `PendingMediaUploadTable`'s row for this task, kept live via
  /// `PendingMediaUploadDao.watchRow` — `null` until a row exists.
  final PendingMediaUploadStatus? uploadStatus;

  ReadAloudState copyWith({bool? isRecording, bool? hasRecorded, PendingMediaUploadStatus? uploadStatus}) {
    return ReadAloudState(
      isRecording: isRecording ?? this.isRecording,
      hasRecorded: hasRecorded ?? this.hasRecorded,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  @override
  List<Object?> get props => [isRecording, hasRecorded, uploadStatus];
}
