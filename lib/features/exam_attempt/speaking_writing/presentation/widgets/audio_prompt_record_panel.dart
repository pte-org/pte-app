import 'package:flutter/material.dart';
import 'package:pte_app/core/widgets/components/pte_status_audio_panel.dart';
import 'package:pte_app/core/widgets/templates/status_speaking_task_frame.dart';
import 'package:pte_app/core/constants/app_strings.dart';

import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_prompt_sub_stage.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_playback_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_listening_status_card.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/recorded_answer_status_card.dart';

/// The shared audio surface for Speaking tasks with a prompt recording.
///
/// Pearson keeps the prompt player and candidate recorder in the same panel:
/// once playback completes, the panel changes its title and controls instead
/// of adding a second audio card below it. The timer remains authoritative for
/// the recording window; playback completion only selects the panel state.
class AudioPromptRecordPanel extends StatelessWidget {
  const AudioPromptRecordPanel({
    super.key,
    required this.task,
    required this.snapshot,
    required this.playback,
    required this.recordingState,
    required this.preListenSeconds,
    required this.preRecordSeconds,
    this.inputLevels,
  });

  final TaskView task;
  final TimerSnapshot? snapshot;
  final AudioPromptPlaybackState playback;
  final AutoRecordState recordingState;
  final int preListenSeconds;
  final int preRecordSeconds;
  final Stream<double>? inputLevels;

  @override
  Widget build(BuildContext context) {
    if (usesStatusAudioPanels(task.taskType)) {
      return PteStatusAudioPair(
        player: AudioListeningPrepCard(
          task: task,
          snapshot: snapshot,
          playback: playback,
          preListenSeconds: preListenSeconds,
          preRecordSeconds: preRecordSeconds,
        ),
        recorder: RecordedAnswerPrepCard(
          task: task,
          snapshot: snapshot,
          recordingState: recordingState,
          inputLevels: inputLevels,
        ),
      );
    }
    final showRecorder = _shouldShowRecorder();
    final panel = showRecorder
        ? RecordedAnswerPrepCard(
            key: const ValueKey('audioPromptRecorderPanel'),
            task: task,
            recordingState: recordingState,
            snapshot: snapshot,
            inputLevels: inputLevels,
          )
        : AudioListeningPrepCard(
            key: const ValueKey('audioPromptPlayerPanel'),
            task: task,
            snapshot: snapshot,
            playback: playback,
            preListenSeconds: preListenSeconds,
            preRecordSeconds: preRecordSeconds,
          );
    return panel;
  }

  bool _shouldShowRecorder() {
    if (recordingState.recordingPhase != RecordingPhase.idle) return true;
    if (snapshot?.phase == TimerPhase.response) return true;
    if (playback.phase == AudioPromptPlaybackPhase.completed) return true;

    final elapsed = elapsedPrepSeconds(task, snapshot);
    final preRecordStart = (task.prepSeconds - preRecordSeconds).clamp(
      0,
      task.prepSeconds,
    );
    return elapsed >= preRecordStart;
  }
}

/// Player state for the prompt's pre-listen and playback sub-stages.
class AudioListeningPrepCard extends StatelessWidget {
  const AudioListeningPrepCard({
    super.key,
    required this.task,
    required this.snapshot,
    required this.playback,
    required this.preListenSeconds,
    required this.preRecordSeconds,
  });

  final TaskView task;
  final TimerSnapshot? snapshot;
  final AudioPromptPlaybackState playback;
  final int preListenSeconds;
  final int preRecordSeconds;

  @override
  Widget build(BuildContext context) {
    final elapsed = elapsedPrepSeconds(task, snapshot);
    if (elapsed < preListenSeconds) {
      final remaining = preListenSeconds - elapsed;
      return AudioListeningStatusCard(
        statusStyle: usesStatusAudioPanels(task.taskType),
        playing: false,
        statusLabel:
            '${SpeakingWritingStrings.recordingBeginningInPrefix}$remaining'
            '${SpeakingWritingStrings.recordingBeginningInSuffix}',
        progress: 0.0,
      );
    }

    final audioSeconds =
        (task.prepSeconds - preListenSeconds - preRecordSeconds).clamp(
          0,
          task.prepSeconds,
        );
    final audioElapsed = (elapsed - preListenSeconds).clamp(0, audioSeconds);
    final audioRemaining = audioSeconds - audioElapsed;
    return AudioListeningStatusCard(
      statusStyle: usesStatusAudioPanels(task.taskType),
      statusLabel: playback.phase == AudioPromptPlaybackPhase.error
          ? playback.errorMessage!
          : usesStatusAudioPanels(task.taskType) &&
                (playback.phase == AudioPromptPlaybackPhase.completed ||
                    audioRemaining <= 0)
          ? AppStrings.audioCompletedLabel
          : '${SpeakingWritingStrings.audioListeningPlayingPrefix}$audioRemaining'
                '${SpeakingWritingStrings.audioListeningPlayingSuffix}',
      progress: audioRemaining <= 0 ? 1.0 : playback.progress,
    );
  }
}

/// Recorder state for the pre-record countdown, response window and upload.
class RecordedAnswerPrepCard extends StatelessWidget {
  const RecordedAnswerPrepCard({
    super.key,
    required this.task,
    required this.recordingState,
    required this.snapshot,
    this.inputLevels,
  });

  final TaskView task;
  final AutoRecordState recordingState;
  final TimerSnapshot? snapshot;
  final Stream<double>? inputLevels;

  @override
  Widget build(BuildContext context) {
    if (recordingState.recordingPhase == RecordingPhase.unavailable) {
      return RecordedAnswerStatusCard(
        statusStyle: usesStatusAudioPanels(task.taskType),
        statusLabel: SpeakingWritingStrings.recordingMicrophoneUnavailableLabel,
        progress: 0.0,
      );
    }
    if (recordingState.recordingPhase == RecordingPhase.recorded) {
      return RecordedAnswerStatusCard(
        statusStyle: usesStatusAudioPanels(task.taskType),
        statusLabel: _uploadStatusLabel(),
        progress: 1.0,
      );
    }
    if (snapshot?.phase == TimerPhase.response) {
      return RecordedAnswerStatusCard(
        statusStyle: usesStatusAudioPanels(task.taskType),
        statusLabel: _countdownLabel(
          prefix: SpeakingWritingStrings.recordingInProgressPrefix,
          suffix: SpeakingWritingStrings.recordingInProgressSuffix,
          remaining: snapshot!.remaining.inSeconds,
        ),
        progress: _elapsedFraction(
          totalSeconds: task.responseSeconds,
          remainingSeconds: snapshot!.remaining.inSeconds,
        ),
        inputLevels: recordingState.recordingPhase == RecordingPhase.recording
            ? inputLevels
            : null,
      );
    }

    final elapsed = elapsedPrepSeconds(task, snapshot);
    final remaining = task.prepSeconds - elapsed;
    return RecordedAnswerStatusCard(
      statusStyle: usesStatusAudioPanels(task.taskType),
      isPreparing: true,
      statusLabel: _countdownLabel(
        prefix: SpeakingWritingStrings.recordingBeginningInPrefix,
        suffix: SpeakingWritingStrings.recordingBeginningInSuffix,
        remaining: remaining,
      ),
      progress: 0.0,
    );
  }

  String _countdownLabel({
    required String prefix,
    required String suffix,
    required int remaining,
  }) {
    return '$prefix$remaining$suffix';
  }

  double _elapsedFraction({
    required int totalSeconds,
    required int remainingSeconds,
  }) {
    if (totalSeconds <= 0) return 1.0;
    final elapsedSeconds = totalSeconds - remainingSeconds;
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
