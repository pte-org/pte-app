import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/dao/pending_media_upload_dao.dart';
import '../../../../core/storage/pending_media_upload_status.dart';
import '../../../../core/sync/media_upload_coordinator.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/audio_recorder_service.dart';
import '../../domain/task_view.dart';
import '../cubit/read_aloud_cubit.dart';
import '../cubit/read_aloud_state.dart';
import '../widgets/exam_scaffold.dart';
import '../widgets/read_aloud_advance_button.dart';

/// Renders inside Phase 4's shared shell as the shell's injected content
/// region — builds no top/bottom chrome of its own (phase-05/06 Design
/// Constraints). The [ReadAloudCubit] is created in [initState] and
/// closed in [dispose].
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
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: ExamScaffold(
        totalTasks: widget.task.totalTasks,
        body: const _RecordingBody(),
        bottomAction: ReadAloudAdvanceButton(
          pinnedItemPublicId: widget.task.pinnedItemPublicId,
          syncEngine: widget.syncEngine,
        ),
      ),
    );
  }
}

class _RecordingBody extends StatelessWidget {
  const _RecordingBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: BlocBuilder<ReadAloudCubit, ReadAloudState>(
        builder: (context, state) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                switch (state.recordingPhase) {
                  RecordingPhase.recording => AppStrings.readAloudRecordingIndicator,
                  RecordingPhase.recorded => _uploadStatusLabel(state),
                  RecordingPhase.idle => AppStrings.readAloudNotRecordedYetLabel,
                },
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              ElevatedButton(
                onPressed: state.recordingPhase == RecordingPhase.recording
                    ? () => context.read<ReadAloudCubit>().stopRecording()
                    : () => context.read<ReadAloudCubit>().startRecording(),
                child: Text(
                  state.recordingPhase == RecordingPhase.recording
                      ? AppStrings.readAloudStopRecordingLabel
                      : AppStrings.readAloudStartRecordingLabel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _uploadStatusLabel(ReadAloudState state) {
    final status = state.uploadStatus;
    if (status == null) return AppStrings.readAloudNotRecordedYetLabel;
    return status == PendingMediaUploadStatus.ready
        ? AppStrings.readAloudUploadReadyLabel
        : AppStrings.readAloudStillUploadingLabel;
  }
}
