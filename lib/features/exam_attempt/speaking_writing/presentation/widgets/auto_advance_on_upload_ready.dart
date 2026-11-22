import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_navigation_constants.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/upload_tracking_state.dart';

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
/// generalization mechanism. Bound by `AutoRecordCubit`/`AutoRecordState`
/// through one shared binding used by every auto-record speaking screen
/// (Read Aloud, Repeat Sentence, Describe Image).
class AutoAdvanceOnUploadReady<
  C extends StateStreamable<S>,
  S extends UploadTrackingState
>
    extends StatefulWidget {
  const AutoAdvanceOnUploadReady({
    super.key,
    required this.pinnedItemPublicId,
    required this.syncEngine,
    this.child = const SizedBox.shrink(),
  });

  final String pinnedItemPublicId;
  final SyncEngine syncEngine;

  /// Shown in place of the (otherwise empty) widget — the speaking screens put
  /// their Next button here so both advance paths live side by side.
  final Widget child;

  @override
  State<AutoAdvanceOnUploadReady<C, S>> createState() =>
      _AutoAdvanceOnUploadReadyState<C, S>();
}

class _AutoAdvanceOnUploadReadyState<
  C extends StateStreamable<S>,
  S extends UploadTrackingState
>
    extends State<AutoAdvanceOnUploadReady<C, S>> {
  bool _isAdvancing = false;
  Timer? _settleTimer;

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);
    try {
      await widget.syncEngine.submitForAdvance(widget.pinnedItemPublicId);
    } catch (_) {
      // Allow a later upload-ready event (or the Next button) to try again.
      if (mounted) setState(() => _isAdvancing = false);
      return;
    }
    if (!mounted) return;
    // Names its own task, so it is ignored if a Next tap already moved on.
    context.read<ExamAttemptBloc>().add(
      NextTaskRequested(fromPinnedItemPublicId: widget.pinnedItemPublicId),
    );
    // The next task replaces this screen. If the bloc ignored the event, free
    // the guard after a while so a later upload-ready event can try again.
    _settleTimer?.cancel();
    _settleTimer = Timer(
      ExamAttemptNavigationConstants.advanceSettleTimeout,
      () {
        if (mounted) setState(() => _isAdvancing = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<C, S>(
      listenWhen: (previous, current) =>
          previous.uploadStatus != PendingMediaUploadStatus.ready &&
          current.uploadStatus == PendingMediaUploadStatus.ready,
      listener: (context, state) => unawaited(_advance()),
      child: widget.child,
    );
  }
}
