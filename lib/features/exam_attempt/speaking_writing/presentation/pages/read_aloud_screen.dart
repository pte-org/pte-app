import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_advance_on_upload_ready.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_record_status_card.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_record_timer_bridge_mixin.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/instruction_text.dart';

/// Renders inside Phase 4's shared shell as the shell's injected content
/// region — builds no top/bottom chrome of its own (phase-05/06 Design
/// Constraints). The [AutoRecordCubit] is created in [initState] and closed
/// in [dispose]. Recording is fully automatic — driven by
/// [AutoRecordTimerBridgeMixin] bridging `ExamAttemptBloc`'s [TimerSnapshot]
/// into the cubit — there is no manual start/stop control, no Skip button,
/// and (via [AutoAdvanceOnUploadReady]) no manual "Next" tap either: once
/// the response window ends and the recording finishes uploading, the
/// attempt advances to the next task on its own, matching real PTE
/// speaking-task behavior.
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

class _ReadAloudScreenState extends State<ReadAloudScreen> with AutoRecordTimerBridgeMixin<ReadAloudScreen> {
  late final AutoRecordCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AutoRecordCubit(
      recorder: widget.recorder,
      mediaDao: widget.mediaDao,
      coordinator: widget.coordinator,
      attemptPublicId: widget.attemptPublicId,
      pinnedItemPublicId: widget.task.pinnedItemPublicId,
    );
    startAutoRecordBridge(task: widget.task, cubit: _cubit);
  }

  @override
  void dispose() {
    disposeAutoRecordBridge();
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
        // Renders nothing — advancing is fully automatic now, driven by
        // AutoAdvanceOnUploadReady's own BlocListener once the upload is
        // ready.
        bottomAction: AutoAdvanceOnUploadReady<AutoRecordCubit, AutoRecordState>(
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
          return BlocBuilder<AutoRecordCubit, AutoRecordState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InstructionText(text: _instructionText(task.responseSeconds)),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  AutoRecordStatusCard(task: task, recordingState: state, snapshot: snapshot),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(task.promptText ?? '', style: const TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _instructionText(int responseSeconds) {
    return '${SpeakingWritingStrings.readAloudInstructionPrefix}$responseSeconds'
        '${SpeakingWritingStrings.readAloudInstructionMiddle}$responseSeconds'
        '${SpeakingWritingStrings.readAloudInstructionSuffix}';
  }
}
