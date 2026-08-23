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
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/task_image_display.dart';

/// Renders inside the shared exam shell as its injected content region —
/// builds no top/bottom chrome of its own. Structurally mirrors
/// `ReadAloudScreen` exactly (same [AutoRecordCubit] lifecycle, same
/// [AutoRecordTimerBridgeMixin] bridge, same [AutoRecordStatusCard], same
/// fully-automatic advance) — the only real difference is the body's
/// content: a 2-variable instruction template (interpolating both
/// `task.prepSeconds` and `task.responseSeconds`, unlike Read Aloud's
/// response-only template) and a displayed image (via [TaskImageDisplay])
/// instead of a scrollable passage.
class DescribeImageScreen extends StatefulWidget {
  const DescribeImageScreen({
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
  State<DescribeImageScreen> createState() => _DescribeImageScreenState();
}

class _DescribeImageScreenState extends State<DescribeImageScreen>
    with AutoRecordTimerBridgeMixin<DescribeImageScreen> {
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
        body: _DescribeImageBody(task: widget.task),
        // Renders nothing — advancing is fully automatic, driven by
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

class _DescribeImageBody extends StatelessWidget {
  const _DescribeImageBody({required this.task});

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
                  InstructionText(text: _instructionText(task.prepSeconds, task.responseSeconds)),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  AutoRecordStatusCard(task: task, recordingState: state, snapshot: snapshot),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Expanded(child: SingleChildScrollView(child: _ImageRegion(imageUrl: task.imagePromptRef))),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _instructionText(int prepSeconds, int responseSeconds) {
    return '${SpeakingWritingStrings.describeImageInstructionPrefix}$prepSeconds'
        '${SpeakingWritingStrings.describeImageInstructionMiddle}$responseSeconds'
        '${SpeakingWritingStrings.describeImageInstructionSuffix}';
  }
}

/// A real `DESCRIBE_IMAGE` task always carries an image per PTE's task
/// definition — a `null` [imageUrl] here is treated as a fixture/data
/// error, not a normal runtime state to design deeply around, but it must
/// still never crash the screen.
class _ImageRegion extends StatelessWidget {
  const _ImageRegion({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null) {
      return Center(
        child: Text(
          SpeakingWritingStrings.taskImageMissingLabel,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      );
    }
    return TaskImageDisplay(imageUrl: url);
  }
}
