import 'package:pte_app/core/storage/pending_media_upload_status.dart';

/// Non-generic seam so a caller (`AutoAdvanceOnUploadReady`) that only needs
/// to know when a recording is safely stored (and later when its upload
/// reaches [PendingMediaUploadStatus.ready]) doesn't need to know which task
/// type's concrete state shape a cubit carries — mirrors
/// `FlushableAnswerCubit`'s existing thin-interface pattern
/// (`task_answer_cubit.dart`).
abstract class UploadTrackingState {
  PendingMediaUploadStatus? get uploadStatus;

  /// True once this screen's own recording has been stopped and its file is
  /// on disk, so the upload can continue in the background after the student
  /// leaves the task.
  bool get hasLocalRecording;
}
