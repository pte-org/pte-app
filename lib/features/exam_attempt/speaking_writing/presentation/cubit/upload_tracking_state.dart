import 'package:pte_app/core/storage/pending_media_upload_status.dart';

/// Non-generic seam so a caller (`AutoAdvanceOnUploadReady`) that only needs
/// to know when a recording's upload reaches [PendingMediaUploadStatus.ready]
/// doesn't need to know which task type's concrete state shape a cubit
/// carries — mirrors `FlushableAnswerCubit`'s existing thin-interface
/// pattern (`task_answer_cubit.dart`).
abstract class UploadTrackingState {
  PendingMediaUploadStatus? get uploadStatus;
}
