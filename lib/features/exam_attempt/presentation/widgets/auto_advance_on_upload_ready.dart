import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/pending_media_upload_status.dart';
import '../../../../core/sync/sync_engine.dart';
import '../bloc/exam_attempt_bloc.dart';
import '../bloc/exam_attempt_event.dart';
import '../cubit/upload_tracking_state.dart';

/// Auto-advances once the recording finishes uploading — real PTE speaking
/// tasks never wait for a manual tap once the response window ends: as soon
/// as [PendingMediaUploadStatus.ready] is reached, this flushes the answer
/// and requests the next task on its own. Renders nothing itself — each
/// task-type screen's own status card is what shows upload progress to the
/// student now.
///
/// Generic over any bloc/state pair exposing [UploadTrackingState] —
/// `StateStreamable<S>` is `flutter_bloc`'s own bound (the same one
/// `BlocListener<B extends StateStreamable<S>, S>` itself uses), so this
/// isn't a new abstraction, just reusing the library's existing
/// generalization mechanism. Shared by `ReadAloudCubit`/`ReadAloudState`
/// and `RepeatSentenceCubit`/`RepeatSentenceState`.
class AutoAdvanceOnUploadReady<C extends StateStreamable<S>, S extends UploadTrackingState>
    extends StatefulWidget {
  const AutoAdvanceOnUploadReady({super.key, required this.pinnedItemPublicId, required this.syncEngine});

  final String pinnedItemPublicId;
  final SyncEngine syncEngine;

  @override
  State<AutoAdvanceOnUploadReady<C, S>> createState() => _AutoAdvanceOnUploadReadyState<C, S>();
}

class _AutoAdvanceOnUploadReadyState<C extends StateStreamable<S>, S extends UploadTrackingState>
    extends State<AutoAdvanceOnUploadReady<C, S>> {
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
    return BlocListener<C, S>(
      listenWhen: (previous, current) =>
          previous.uploadStatus != PendingMediaUploadStatus.ready &&
          current.uploadStatus == PendingMediaUploadStatus.ready,
      listener: (context, state) => unawaited(_advance()),
      child: const SizedBox.shrink(),
    );
  }
}
