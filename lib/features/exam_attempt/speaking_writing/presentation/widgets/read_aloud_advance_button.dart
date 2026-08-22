import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_state.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';

/// Gated variant of Phase 5's `TaskAdvanceButton`: a `READ_ALOUD` answer
/// isn't in the outbox at all until its `PendingMediaUploadTable` row
/// reaches [PendingMediaUploadStatus.ready] (phase-06 Design Constraints)
/// — advancing before then would leave nothing for `SyncEngine.flushOne`
/// to submit. Disabled (not hidden) while still uploading/completing, so
/// the student sees a visible "still uploading" state rather than a
/// missing button.
class ReadAloudAdvanceButton extends StatefulWidget {
  const ReadAloudAdvanceButton({super.key, required this.pinnedItemPublicId, required this.syncEngine});

  final String pinnedItemPublicId;
  final SyncEngine syncEngine;

  @override
  State<ReadAloudAdvanceButton> createState() => _ReadAloudAdvanceButtonState();
}

class _ReadAloudAdvanceButtonState extends State<ReadAloudAdvanceButton> {
  bool _isAdvancing = false;

  Future<void> _advance() async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);
    await widget.syncEngine.flushOne(widget.pinnedItemPublicId);
    if (!mounted) return;
    context.read<ExamAttemptBloc>().add(const NextTaskRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ReadAloudCubit, ReadAloudState, bool>(
      selector: (state) => state.uploadStatus == PendingMediaUploadStatus.ready,
      builder: (context, isReady) {
        return PrimaryButton(
          label: isReady ? ExamAttemptStrings.taskAdvanceButtonLabel : SpeakingWritingStrings.readAloudStillUploadingLabel,
          onPressed: isReady ? _advance : null,
          isLoading: _isAdvancing,
        );
      },
    );
  }
}
