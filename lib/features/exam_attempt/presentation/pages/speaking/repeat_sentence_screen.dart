import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/storage/dao/pending_media_upload_dao.dart';
import '../../../../../core/storage/pending_media_upload_status.dart';
import '../../../../../core/sync/media_upload_coordinator.dart';
import '../../../../../core/sync/sync_engine.dart';
import '../../../domain/audio_recorder_service.dart';
import '../../../domain/task_view.dart';
import '../../../domain/timer_phase.dart';
import '../../../domain/timer_snapshot.dart';
import '../../bloc/exam_attempt_bloc.dart';
import '../../bloc/exam_attempt_state.dart';
import '../../cubit/recording_phase.dart';
import '../../cubit/repeat_sentence_cubit.dart';
import '../../cubit/repeat_sentence_state.dart';
import '../../widgets/audio_listening_status_card.dart';
import '../../widgets/auto_advance_on_upload_ready.dart';
import '../../widgets/exam_scaffold.dart';
import '../../widgets/instruction_text.dart';
import '../../widgets/recorded_answer_status_card.dart';

/// Mock-only sub-stage split within the shared `prep` window — real PTE
/// varies these per question; this app has no per-stage data from the
/// backend (or real audio playback) to derive them from, so both boundary
/// durations are fixed regardless of the task's actual `prepSeconds`. The
/// "audio playing" duration is whatever remains:
/// `prepSeconds - preListenSeconds - preRecordSeconds`.
const int _preListenSeconds = 3;
const int _preRecordSeconds = 3;

/// Renders inside the shared exam shell as its injected content region —
/// builds no top/bottom chrome of its own. Structurally mirrors
/// `ReadAloudScreen` exactly (same [RepeatSentenceCubit] lifecycle, same
/// timer-bridge mechanics, same fully-automatic advance) — duplicated, not
/// shared, per this plan's "extract at the 3rd occurrence" decision.
///
/// The `prep` phase here covers the whole real-world "listening" sequence:
/// pre-listen prep ([_preListenSeconds]) → mocked audio playback → pre-
/// record prep ([_preRecordSeconds]) → then `response` is the actual
/// recording. Both [AudioListeningStatusCard] (top) and
/// [RecordedAnswerStatusCard] (bottom, "Recorded Answer") are visible the
/// whole time — each runs its own independent "Beginning in" →
/// active-countdown sequence, not swapped in and out of view.
class RepeatSentenceScreen extends StatefulWidget {
  const RepeatSentenceScreen({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.recorder,
    required this.mediaDao,
    required this.coordinator,
    required this.syncEngine,
  });

  final TaskView task;
  final String attemptPublicId;
  final AudioRecorderService recorder;
  final PendingMediaUploadDao mediaDao;
  final MediaUploadCoordinator coordinator;
  final SyncEngine syncEngine;

  @override
  State<RepeatSentenceScreen> createState() => _RepeatSentenceScreenState();
}

class _RepeatSentenceScreenState extends State<RepeatSentenceScreen> {
  late final RepeatSentenceCubit _cubit;
  StreamSubscription<ExamAttemptState>? _timerBridgeSubscription;

  @override
  void initState() {
    super.initState();
    _cubit = RepeatSentenceCubit(
      recorder: widget.recorder,
      mediaDao: widget.mediaDao,
      coordinator: widget.coordinator,
      attemptPublicId: widget.attemptPublicId,
      pinnedItemPublicId: widget.task.pinnedItemPublicId,
    );
    final bloc = context.read<ExamAttemptBloc>();
    // Seed from the bloc's current state immediately (covers resuming
    // mid-task — don't wait for the next ~1s tick), then keep forwarding
    // for the screen's lifetime.
    _forwardIfCurrentTask(bloc.state);
    _timerBridgeSubscription = bloc.stream.listen(_forwardIfCurrentTask);
  }

  /// Bridges `ExamAttemptBloc`'s clock into the cubit — the single
  /// authoritative source, never a second timer. Guards on
  /// `pinnedItemPublicId` matching this screen's own task:
  /// `TaskTypeDispatcher` defers the outgoing screen's `dispose()` to
  /// end-of-frame while the bloc's next-task emission is delivered via
  /// microtask, so a stale screen's subscription can otherwise receive the
  /// *new* task's first snapshot before its own teardown runs — reachable
  /// via proctor-forced/rejected-submission advances, which bypass the
  /// recorded/upload gate that makes the normal advance path safe (the same
  /// CRITICAL bug class already fixed once for `ReadAloudScreen`; this
  /// guard is mandatory, not optional).
  void _forwardIfCurrentTask(ExamAttemptState state) {
    if (state is! AttemptInProgress) return;
    if (state.task.pinnedItemPublicId != widget.task.pinnedItemPublicId) return;
    _cubit.onTimerSnapshot(state.timerSnapshot);
  }

  @override
  void dispose() {
    unawaited(_timerBridgeSubscription?.cancel());
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: ExamScaffold(
        totalTasks: widget.task.totalTasks,
        body: _RepeatSentenceBody(task: widget.task),
        // Renders nothing — advancing is fully automatic, driven by
        // AutoAdvanceOnUploadReady's own BlocListener once the upload is
        // ready.
        bottomAction: AutoAdvanceOnUploadReady<RepeatSentenceCubit, RepeatSentenceState>(
          pinnedItemPublicId: widget.task.pinnedItemPublicId,
          syncEngine: widget.syncEngine,
        ),
      ),
    );
  }
}

class _RepeatSentenceBody extends StatelessWidget {
  const _RepeatSentenceBody({required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerSnapshot?>(
        selector: (state) => state is AttemptInProgress ? state.timerSnapshot : null,
        builder: (context, snapshot) {
          return BlocBuilder<RepeatSentenceCubit, RepeatSentenceState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InstructionText(text: AppStrings.repeatSentenceInstructionText),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _ListeningCard(task: task, snapshot: snapshot),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _RecordCard(task: task, recordingState: state, snapshot: snapshot),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// How much of the shared `prep` window has elapsed, clamped to
/// `[0, task.prepSeconds]` — once `response` begins (or the task is
/// recorded), prep is by definition fully elapsed, which is exactly what
/// [_ListeningCard] needs to render its final ("audio finished") state
/// without any extra phase branching.
int _elapsedPrepSeconds(TaskView task, TimerSnapshot? snapshot) {
  if (snapshot == null) return 0;
  if (snapshot.phase == TimerPhase.response) return task.prepSeconds;
  return (task.prepSeconds - snapshot.remaining.inSeconds).clamp(0, task.prepSeconds);
}

/// Top card — its own independent "Beginning in" (pre-listen prep) →
/// "Playing" (mocked audio) sequence, driven purely by how much of the
/// shared prep window has elapsed. The progress bar only fills during the
/// active "Playing" sub-stage, staying empty through "Beginning in". Never
/// shows a recording-related label — that's [_RecordCard]'s concern.
class _ListeningCard extends StatelessWidget {
  const _ListeningCard({required this.task, required this.snapshot});

  final TaskView task;
  final TimerSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final elapsed = _elapsedPrepSeconds(task, snapshot);
    if (elapsed < _preListenSeconds) {
      final remaining = _preListenSeconds - elapsed;
      return AudioListeningStatusCard(
        statusLabel: '${AppStrings.recordingBeginningInPrefix}$remaining${AppStrings.recordingBeginningInSuffix}',
        // The progress bar only tracks the *active* (Playing/Recording)
        // sub-stage — it stays empty during "Beginning in" prep, per the
        // user's confirmed decision.
        progress: 0.0,
      );
    }
    final audioSeconds = (task.prepSeconds - _preListenSeconds - _preRecordSeconds).clamp(0, task.prepSeconds);
    final audioElapsed = (elapsed - _preListenSeconds).clamp(0, audioSeconds);
    final audioRemaining = audioSeconds - audioElapsed;
    return AudioListeningStatusCard(
      statusLabel:
          '${AppStrings.audioListeningPlayingPrefix}$audioRemaining${AppStrings.audioListeningPlayingSuffix}',
      progress: audioSeconds <= 0 ? 1.0 : audioElapsed / audioSeconds,
    );
  }
}

/// Bottom card ("Recorded Answer", reusing [RecordedAnswerStatusCard]) —
/// blank while [_ListeningCard] is still active, then its own independent
/// "Beginning in" (pre-record prep) → "Recording" → upload-status
/// sequence once the listening sequence finishes. Recorded phase always
/// wins over the live timer phase, regardless of sub-stage.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.task, required this.recordingState, required this.snapshot});

  final TaskView task;
  final RepeatSentenceState recordingState;
  final TimerSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    if (recordingState.recordingPhase == RecordingPhase.recorded) {
      return RecordedAnswerStatusCard(statusLabel: _uploadStatusLabel(), progress: 1.0);
    }
    if (snapshot?.phase == TimerPhase.response) {
      return RecordedAnswerStatusCard(
        statusLabel: _countdownLabel(
          prefix: AppStrings.recordingInProgressPrefix,
          suffix: AppStrings.recordingInProgressSuffix,
          remaining: snapshot!.remaining.inSeconds,
        ),
        progress: _elapsedFraction(totalSeconds: task.responseSeconds, remainingSeconds: snapshot!.remaining.inSeconds),
      );
    }

    final elapsed = _elapsedPrepSeconds(task, snapshot);
    final preRecordStart = (task.prepSeconds - _preRecordSeconds).clamp(0, task.prepSeconds);
    if (elapsed < preRecordStart) {
      // Still in the listening sequence — nothing to show here yet.
      return const RecordedAnswerStatusCard(statusLabel: '', progress: 0.0);
    }
    final remaining = task.prepSeconds - elapsed;
    return RecordedAnswerStatusCard(
      statusLabel: _countdownLabel(
        prefix: AppStrings.recordingBeginningInPrefix,
        suffix: AppStrings.recordingBeginningInSuffix,
        remaining: remaining,
      ),
      // Empty during "Beginning in" prep, same rule as the Listening
      // card — only the actual Recording sub-stage above fills this bar.
      progress: 0.0,
    );
  }

  String _countdownLabel({required String prefix, required String suffix, required int remaining}) {
    return '$prefix$remaining$suffix';
  }

  double _elapsedFraction({required int totalSeconds, required int remainingSeconds}) {
    if (totalSeconds <= 0) return 1.0;
    final elapsedSeconds = totalSeconds - remainingSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  String _uploadStatusLabel() {
    final status = recordingState.uploadStatus;
    if (status == null) return AppStrings.recordingStillUploadingLabel;
    return status == PendingMediaUploadStatus.ready
        ? AppStrings.recordingUploadReadyLabel
        : AppStrings.recordingStillUploadingLabel;
  }
}
