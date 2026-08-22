import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/pending_media_upload_status.dart';
import '../../../../core/sync/sync_engine.dart';
import '../bloc/exam_attempt_bloc.dart';
import '../bloc/exam_attempt_event.dart';
import '../cubit/read_aloud_cubit.dart';
import '../cubit/read_aloud_state.dart';

/// Auto-advances once the recording finishes uploading — real PTE speaking
/// tasks never wait for a manual tap once the response window ends: as soon
/// as [PendingMediaUploadStatus.ready] is reached, this flushes the answer
/// and requests the next task on its own. Renders nothing itself — the
/// `ReadAloudAnswerStatusCard` in the body is what shows upload progress to
/// the student now (this replaces the old tappable `ReadAloudAdvanceButton`).
class ReadAloudAutoAdvance extends StatefulWidget {
  const ReadAloudAutoAdvance({super.key, required this.pinnedItemPublicId, required this.syncEngine});

  final String pinnedItemPublicId;
  final SyncEngine syncEngine;

  @override
  State<ReadAloudAutoAdvance> createState() => _ReadAloudAutoAdvanceState();
}

class _ReadAloudAutoAdvanceState extends State<ReadAloudAutoAdvance> {
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
    return BlocListener<ReadAloudCubit, ReadAloudState>(
      listenWhen: (previous, current) =>
          previous.uploadStatus != PendingMediaUploadStatus.ready &&
          current.uploadStatus == PendingMediaUploadStatus.ready,
      listener: (context, state) => unawaited(_advance()),
      child: const SizedBox.shrink(),
    );
  }
}
