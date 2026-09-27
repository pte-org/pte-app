import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_prompt_sub_stage.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_playback_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_listening_status_card.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/recorded_answer_status_card.dart';
import 'package:pte_app/core/widgets/templates/record_response_template.dart';

export 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_prompt_sub_stage.dart';

/// Shared body for every Speaking-task screen whose `prep` phase covers a
/// pre-listen countdown → mocked audio playback → pre-record countdown,
/// followed by an actual recording `response` phase — currently
/// `RepeatSentenceScreen`, `RetellLectureScreen`, `AnswerShortQuestionScreen`,
/// and `SummarizeGroupDiscussionScreen`.
/// Extracted once this shape hit this project's 3-occurrence DRY threshold
/// (same rule that previously unified `AutoRecordCubit`/
/// `AutoRecordTimerBridgeMixin` for Read Aloud/Describe Image). A pure move
/// of what was 3x-duplicated `elapsedPrepSeconds`/`AudioListeningPrepCard`/
/// `RecordedAnswerPrepCard` — zero behavior change, only [preListenSeconds]/
/// [preRecordSeconds] moved from module-level constants to constructor
/// params so screens with different sub-stage splits can share one copy.
///
/// [instructionText] is a fully pre-built string — screens differ in
/// whether it's a fixed constant (Repeat Sentence, Answer Short Question,
/// Summarize Group Discussion) or interpolated from [preRecordSeconds]/
/// `task.responseSeconds` (Retell Lecture); this widget has no opinion on
/// that, it just renders whatever string it's given. Callers are
/// responsible for keeping any interpolated value consistent with the
/// [preRecordSeconds] passed here.
///
/// [elapsedPrepSeconds]/[AudioListeningPrepCard]/[RecordedAnswerPrepCard]
/// are public (not `_`-prefixed) so `RespondToASituationScreen` can compose
/// them directly alongside a persistent situation-text display that this
/// widget's own fixed internal layout can't interleave — a mechanical
/// rename, not a new abstraction; behavior is identical to before.
class AudioPromptRecordBody extends StatelessWidget {
  const AudioPromptRecordBody({
    super.key,
    required this.task,
    required this.preListenSeconds,
    required this.preRecordSeconds,
    required this.instructionText,
  });

  final TaskView task;
  final int preListenSeconds;
  final int preRecordSeconds;
  final String instructionText;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerSnapshot?>(
      selector: (state) =>
          state is AttemptInProgress ? state.timerSnapshot : null,
      builder: (context, snapshot) {
        return BlocBuilder<AutoRecordCubit, AutoRecordState>(
          builder: (context, state) {
            return RecordResponseTemplate(
              title:
                  TaskTypeMeta.forTaskType(task.taskType)?.title ?? task.title,
              subtitle: task.section,
              instruction: instructionText,
              stimulus: AudioListeningPrepCard(
                task: task,
                snapshot: snapshot,
                preListenSeconds: preListenSeconds,
                preRecordSeconds: preRecordSeconds,
              ),
              response: RecordedAnswerPrepCard(
                task: task,
                recordingState: state,
                snapshot: snapshot,
                preRecordSeconds: preRecordSeconds,
              ),
            );
          },
        );
      },
    );
  }
}

/// Top card — its own independent "Beginning in" (pre-listen prep) →
/// "Playing" (mocked audio) sequence, driven purely by how much of the
/// shared prep window has elapsed. The progress bar only fills during the
/// active "Playing" sub-stage, staying empty through "Beginning in". Never
/// shows a recording-related label — that's [RecordedAnswerPrepCard]'s
/// concern.
class AudioListeningPrepCard extends StatelessWidget {
  const AudioListeningPrepCard({
    super.key,
    required this.task,
    required this.snapshot,
    required this.preListenSeconds,
    required this.preRecordSeconds,
  });

  final TaskView task;
  final TimerSnapshot? snapshot;
  final int preListenSeconds;
  final int preRecordSeconds;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExamAttemptBloc, ExamAttemptState, bool>(
      selector: (state) => state is AttemptInProgress && state.isPractice,
      builder: (context, isPractice) {
        if (isPractice) {
          return BlocBuilder<AudioPromptCubit, AudioPromptPlaybackState>(
            builder: (context, playback) =>
                _PracticeListenCard(playback: playback),
          );
        }
        return _buildOfficialListenCard(context);
      },
    );
  }

  Widget _buildOfficialListenCard(BuildContext context) {
    final elapsed = elapsedPrepSeconds(task, snapshot);
    if (elapsed < preListenSeconds) {
      final remaining = preListenSeconds - elapsed;
      return AudioListeningStatusCard(
        statusLabel:
            '${SpeakingWritingStrings.recordingBeginningInPrefix}$remaining'
            '${SpeakingWritingStrings.recordingBeginningInSuffix}',
        // The progress bar only tracks the *active* (Playing/Recording)
        // sub-stage — it stays empty during "Beginning in" prep, per the
        // user's confirmed decision.
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
    // The fill amount comes from AudioPromptCubit's real playback position
    // (plans/phat-speaking-audio-prompt-e2e, user's confirmed decision) —
    // only the countdown label text stays timer-driven, since the server
    // reports no per-sub-stage timing of its own to label against. Once the
    // elapsed-time window has closed (audioRemaining <= 0, i.e. the label
    // already reads "0 seconds left"), the bar is forced to 1.0 instead of
    // trusting the cubit's still-possibly-catching-up real position —
    // real playback start lags the theoretical window's start by however
    // long the presigned-URL fetch/buffer takes, so the real player can
    // still be short of `duration` for up to that same lag at the window's
    // close (plans/phat-speaking-dynamic-prep-timing Phase 5 walkthrough
    // finding: the bar visibly failed to reach 100% even though the label
    // had already finished counting down).
    return BlocBuilder<AudioPromptCubit, AudioPromptPlaybackState>(
      builder: (context, playback) {
        return AudioListeningStatusCard(
          statusLabel: playback.phase == AudioPromptPlaybackPhase.error
              ? playback.errorMessage!
              : '${SpeakingWritingStrings.audioListeningPlayingPrefix}$audioRemaining'
                    '${SpeakingWritingStrings.audioListeningPlayingSuffix}',
          progress: audioRemaining <= 0 ? 1.0 : playback.progress,
        );
      },
    );
  }
}

/// Bottom card ("Recorded Answer", reusing [RecordedAnswerStatusCard]) —
/// blank while [AudioListeningPrepCard] is still active, then its own
/// independent "Beginning in" (pre-record prep) → "Recording" → upload-
/// status sequence once the listening sequence finishes. Recorded phase
/// always wins over the live timer phase, regardless of sub-stage.
class RecordedAnswerPrepCard extends StatelessWidget {
  const RecordedAnswerPrepCard({
    super.key,
    required this.task,
    required this.recordingState,
    required this.snapshot,
    required this.preRecordSeconds,
  });

  final TaskView task;
  final AutoRecordState recordingState;
  final TimerSnapshot? snapshot;
  final int preRecordSeconds;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExamAttemptBloc, ExamAttemptState, bool>(
      selector: (state) => state is AttemptInProgress && state.isPractice,
      builder: (context, isPractice) {
        if (isPractice) {
          return _PracticeRecordCard(
            recordingState: recordingState,
            responseSeconds: task.responseSeconds,
          );
        }
        return _buildOfficialRecordCard();
      },
    );
  }

  Widget _buildOfficialRecordCard() {
    if (recordingState.recordingPhase == RecordingPhase.unavailable) {
      return const RecordedAnswerStatusCard(
        statusLabel: SpeakingWritingStrings.recordingMicrophoneUnavailableLabel,
        progress: 0.0,
      );
    }
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
          remaining: snapshot!.remaining.inSeconds,
        ),
        progress: _elapsedFraction(
          totalSeconds: task.responseSeconds,
          remainingSeconds: snapshot!.remaining.inSeconds,
        ),
      );
    }

    final elapsed = elapsedPrepSeconds(task, snapshot);
    final preRecordStart = (task.prepSeconds - preRecordSeconds).clamp(
      0,
      task.prepSeconds,
    );
    if (elapsed < preRecordStart) {
      // Still in the listening sequence — nothing to show here yet.
      return const RecordedAnswerStatusCard(statusLabel: '', progress: 0.0);
    }
    final remaining = task.prepSeconds - elapsed;
    return RecordedAnswerStatusCard(
      statusLabel: _countdownLabel(
        prefix: SpeakingWritingStrings.recordingBeginningInPrefix,
        suffix: SpeakingWritingStrings.recordingBeginningInSuffix,
        remaining: remaining,
      ),
      // Empty during "Beginning in" prep, same rule as the Listening
      // card — only the actual Recording sub-stage above fills this bar.
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

/// Practice-mode listening card — shows current playback state and a manual
/// "Tap to listen" / "Listen again" button. Replaces the timer-driven
/// countdown display that official mode uses.
class _PracticeListenCard extends StatelessWidget {
  const _PracticeListenCard({required this.playback});

  final AudioPromptPlaybackState playback;

  @override
  Widget build(BuildContext context) {
    final isLoading = playback.phase == AudioPromptPlaybackPhase.loading;

    final String statusLabel;
    switch (playback.phase) {
      case AudioPromptPlaybackPhase.idle:
        statusLabel = SpeakingWritingStrings.practiceListenTapLabel;
      case AudioPromptPlaybackPhase.loading:
        statusLabel = SpeakingWritingStrings.practiceListenLoadingLabel;
      case AudioPromptPlaybackPhase.playing:
        statusLabel = SpeakingWritingStrings.practiceListenPlayingLabel;
      case AudioPromptPlaybackPhase.error:
        statusLabel =
            playback.errorMessage ??
            SpeakingWritingStrings.audioPromptGenericErrorMessage;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AudioListeningStatusCard(
          statusLabel: statusLabel,
          progress: playback.phase == AudioPromptPlaybackPhase.playing
              ? playback.progress
              : 0.0,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () => unawaited(
                  context.read<AudioPromptCubit>().playManually(),
                ),
          icon: const Icon(Icons.play_circle_outline),
          label: Text(
            playback.phase == AudioPromptPlaybackPhase.idle
                ? SpeakingWritingStrings.practiceListenTapLabel
                : SpeakingWritingStrings.practiceListenAgainLabel,
          ),
        ),
      ],
    );
  }
}

/// Practice-mode record card — shows "Start Recording" / "Record again"
/// buttons driven by manual taps; auto-stops after [responseSeconds] with
/// a live progress bar. No manual "Stop" button — the time limit enforces
/// the upper bound instead.
class _PracticeRecordCard extends StatefulWidget {
  const _PracticeRecordCard({
    required this.recordingState,
    required this.responseSeconds,
  });

  final AutoRecordState recordingState;
  final int responseSeconds;

  @override
  State<_PracticeRecordCard> createState() => _PracticeRecordCardState();
}

class _PracticeRecordCardState extends State<_PracticeRecordCard> {
  Timer? _timer;
  double _progress = 0.0;

  @override
  void didUpdateWidget(_PracticeRecordCard old) {
    super.didUpdateWidget(old);
    final wasRecording =
        old.recordingState.recordingPhase == RecordingPhase.recording;
    final isRecording =
        widget.recordingState.recordingPhase == RecordingPhase.recording;
    if (!wasRecording && isRecording) {
      _progress = 0.0;
      _startTimer();
    } else if (wasRecording && !isRecording) {
      _cancelTimer();
    }
  }

  void _startTimer() {
    _cancelTimer();
    const tick = 100; // ms
    final totalMs = widget.responseSeconds * 1000;
    int elapsed = 0;
    _timer = Timer.periodic(const Duration(milliseconds: tick), (t) {
      elapsed += tick;
      if (!mounted) { t.cancel(); return; }
      final p = (elapsed / totalMs).clamp(0.0, 1.0);
      setState(() => _progress = p);
      if (elapsed >= totalMs) {
        t.cancel();
        _autoStop();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _autoStop() {
    if (!mounted) return;
    final cubit = context.read<AutoRecordCubit>();
    if (cubit.state.recordingPhase == RecordingPhase.recording) {
      unawaited(cubit.stopRecording());
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.recordingState.recordingPhase;

    final String statusLabel;
    switch (phase) {
      case RecordingPhase.idle:
        statusLabel = SpeakingWritingStrings.practiceRecordIdleLabel;
      case RecordingPhase.recording:
        statusLabel = SpeakingWritingStrings.readAloudRecordingIndicator;
      case RecordingPhase.recorded:
        statusLabel = SpeakingWritingStrings.practiceRecordedLabel;
      case RecordingPhase.unavailable:
        return const RecordedAnswerStatusCard(
          statusLabel:
              SpeakingWritingStrings.recordingMicrophoneUnavailableLabel,
          progress: 0.0,
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecordedAnswerStatusCard(
          statusLabel: statusLabel,
          progress: phase == RecordingPhase.recording
              ? _progress
              : phase == RecordingPhase.recorded
                  ? 1.0
                  : 0.0,
        ),
        if (phase == RecordingPhase.idle || phase == RecordingPhase.recorded) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                unawaited(context.read<AutoRecordCubit>().startRecording()),
            icon: const Icon(Icons.mic),
            label: Text(
              phase == RecordingPhase.idle
                  ? SpeakingWritingStrings.readAloudStartRecordingLabel
                  : SpeakingWritingStrings.practiceRecordAgainLabel,
            ),
          ),
        ],
      ],
    );
  }
}
