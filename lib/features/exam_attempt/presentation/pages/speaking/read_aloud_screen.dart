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
import '../../cubit/read_aloud_cubit.dart';
import '../../cubit/read_aloud_state.dart';
import '../../widgets/exam_scaffold.dart';
import '../../widgets/read_aloud_advance_button.dart';
import '../../widgets/read_aloud_passage_panel.dart';
import '../../widgets/read_aloud_recording_indicator.dart';

/// Renders inside Phase 4's shared shell as the shell's injected content
/// region — builds no top/bottom chrome of its own (phase-05/06 Design
/// Constraints). The [ReadAloudCubit] is created in [initState] and closed
/// in [dispose]. Recording is fully automatic — driven by bridging
/// `ExamAttemptBloc`'s [TimerSnapshot] into the cubit — there is no manual
/// start/stop control and no Skip button.
class ReadAloudScreen extends StatefulWidget {
  const ReadAloudScreen({
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
  State<ReadAloudScreen> createState() => _ReadAloudScreenState();
}

class _ReadAloudScreenState extends State<ReadAloudScreen> {
  late final ReadAloudCubit _cubit;
  StreamSubscription<ExamAttemptState>? _timerBridgeSubscription;

  @override
  void initState() {
    super.initState();
    _cubit = ReadAloudCubit(
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
  /// authoritative source (see `ReadAloudCubit.onTimerSnapshot`'s doc),
  /// never a second timer. Guards on `pinnedItemPublicId` matching this
  /// screen's own task: `TaskTypeDispatcher` defers the outgoing screen's
  /// `dispose()` to end-of-frame while the bloc's next-task emission is
  /// delivered via microtask, so a stale screen's subscription can
  /// otherwise receive the *new* task's first snapshot before its own
  /// teardown runs — reachable via proctor-forced/rejected-submission
  /// advances, which bypass the recorded/upload gate that makes the normal
  /// advance path safe (plan-reviewer CRITICAL finding).
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
        body: _ReadAloudBody(task: widget.task),
        bottomAction: ReadAloudAdvanceButton(
          pinnedItemPublicId: widget.task.pinnedItemPublicId,
          syncEngine: widget.syncEngine,
        ),
      ),
    );
  }
}

class _ReadAloudBody extends StatelessWidget {
  const _ReadAloudBody({required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerSnapshot?>(
        selector: (state) => state is AttemptInProgress ? state.timerSnapshot : null,
        builder: (context, snapshot) {
          return BlocBuilder<ReadAloudCubit, ReadAloudState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: ReadAloudPassagePanel(promptText: task.promptText ?? '', responseSeconds: task.responseSeconds),
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _StatusArea(task: task, recordingState: state, snapshot: snapshot),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Recorded phase always wins (upload status), regardless of the live timer
/// phase; otherwise response phase shows the recording indicator and prep
/// phase shows the auto-record hint.
class _StatusArea extends StatelessWidget {
  const _StatusArea({required this.task, required this.recordingState, required this.snapshot});

  final TaskView task;
  final ReadAloudState recordingState;
  final TimerSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    if (recordingState.recordingPhase == RecordingPhase.recorded) {
      return Text(_uploadStatusLabel());
    }
    if (snapshot?.phase == TimerPhase.response) {
      final total = Duration(seconds: task.responseSeconds);
      return ReadAloudRecordingIndicator(
        isRecording: recordingState.recordingPhase == RecordingPhase.recording,
        elapsed: total - snapshot!.remaining,
        total: total,
      );
    }
    return Text(AppStrings.readAloudPrepHintLabel);
  }

  String _uploadStatusLabel() {
    final status = recordingState.uploadStatus;
    if (status == null) return AppStrings.readAloudStillUploadingLabel;
    return status == PendingMediaUploadStatus.ready
        ? AppStrings.readAloudUploadReadyLabel
        : AppStrings.readAloudStillUploadingLabel;
  }
}
