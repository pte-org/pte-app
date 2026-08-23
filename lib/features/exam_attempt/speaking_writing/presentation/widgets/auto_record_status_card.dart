import 'package:flutter/material.dart';

import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/recorded_answer_status_card.dart';

/// Single-card recorded/response/prep state machine for an auto-record
/// speaking task — recorded phase always wins (upload status), regardless
/// of the live timer phase; otherwise response phase shows a live
/// "Recording" countdown and prep phase shows a live "Beginning in…"
/// countdown — both driven by the same [RecordedAnswerStatusCard] shell
/// with a phase-appropriate `statusLabel`/`progress`.
///
/// Extracted out of `ReadAloudScreen`'s private `_StatusCard` once Describe
/// Image needed the exact same shape (this project's 3-occurrence DRY
/// threshold — 2 concrete uses today, Read Aloud and Describe Image, would
/// have hit a 3rd if any future screen needed it). `RepeatSentenceScreen`'s
/// `RecordedAnswerPrepCard` is deliberately **not** merged into this — it has extra
/// pre-record sub-stage clamping logic (`elapsedPrepSeconds`,
/// `preRecordSeconds` boundary) that genuinely diverges from this simpler,
/// non-sub-staged shape, so forcing a shared abstraction there would add
/// branching complexity for no duplication removed.
class AutoRecordStatusCard extends StatelessWidget {
  const AutoRecordStatusCard({
    super.key,
    required this.task,
    required this.recordingState,
    required this.snapshot,
  });

  final TaskView task;
  final AutoRecordState recordingState;
  final TimerSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    if (recordingState.recordingPhase == RecordingPhase.recorded) {
      return RecordedAnswerStatusCard(
        statusLabel: _uploadStatusLabel(),
        progress: 1.0,
      );
    }
    if (snapshot?.phase == TimerPhase.response) {
      return RecordedAnswerStatusCard(
        statusLabel: _countdownLabel(
          prefix: SpeakingWritingStrings.recordingInProgressPrefix,
          suffix: SpeakingWritingStrings.recordingInProgressSuffix,
          remaining: snapshot!.remaining,
        ),
        progress: _elapsedFraction(
          totalSeconds: task.responseSeconds,
          remaining: snapshot!.remaining,
        ),
      );
    }
    final remaining =
        snapshot?.remaining ?? Duration(seconds: task.prepSeconds);
    return RecordedAnswerStatusCard(
      statusLabel: _countdownLabel(
        prefix: SpeakingWritingStrings.recordingBeginningInPrefix,
        suffix: SpeakingWritingStrings.recordingBeginningInSuffix,
        remaining: remaining,
      ),
      // The progress bar only tracks the active "Recording…" sub-stage —
      // it stays empty during "Beginning in…" prep (matches
      // RepeatSentenceScreen's identical rule).
      progress: 0.0,
    );
  }

  String _countdownLabel({
    required String prefix,
    required String suffix,
    required Duration remaining,
  }) {
    return '$prefix${remaining.inSeconds}$suffix';
  }

  double _elapsedFraction({
    required int totalSeconds,
    required Duration remaining,
  }) {
    if (totalSeconds <= 0) return 1.0;
    final elapsedSeconds = totalSeconds - remaining.inSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  String _uploadStatusLabel() {
    final status = recordingState.uploadStatus;
    if (status == null) {
      return SpeakingWritingStrings.recordingStillUploadingLabel;
    }
    return status == PendingMediaUploadStatus.ready
        ? SpeakingWritingStrings.recordingUploadReadyLabel
        : SpeakingWritingStrings.recordingStillUploadingLabel;
  }
}
