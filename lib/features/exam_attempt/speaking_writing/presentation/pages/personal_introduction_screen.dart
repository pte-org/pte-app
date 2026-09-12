import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
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
import 'package:pte_app/core/widgets/templates/record_response_template.dart';

/// Renders inside the shared exam shell as its injected content region —
/// builds no top/bottom chrome of its own. Structurally mirrors
/// `ReadAloudScreen` exactly (same [AutoRecordCubit] lifecycle, same
/// [AutoRecordTimerBridgeMixin] bridge, same single [AutoRecordStatusCard],
/// same fully-automatic advance via [AutoAdvanceOnUploadReady] — no manual
/// "Next" button, despite one appearing in the reference mockup; the
/// unscored `PERSONAL_INTRODUCTION` task type still follows this app's
/// established fully-automatic Speaking-task behavior, confirmed explicitly
/// by the user rather than assumed from the mockup) — the only real
/// difference is the body's instruction text: a 2-variable template
/// (interpolating both `task.prepSeconds` and `task.responseSeconds`, same
/// shape as `DescribeImageScreen`'s, NOT `ReadAloudScreen`'s single-variable
/// one) and no image/passage beyond the plain prompt text (the bulleted
/// topic suggestions PTE shows for this task).
class PersonalIntroductionScreen extends StatefulWidget {
  const PersonalIntroductionScreen({
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
  State<PersonalIntroductionScreen> createState() =>
      _PersonalIntroductionScreenState();
}

class _PersonalIntroductionScreenState extends State<PersonalIntroductionScreen>
    with AutoRecordTimerBridgeMixin<PersonalIntroductionScreen> {
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
        body: _PersonalIntroductionBody(task: widget.task),
        // Renders nothing — advancing is fully automatic, driven by
        // AutoAdvanceOnUploadReady's own BlocListener once the upload is
        // ready.
        bottomAction:
            AutoAdvanceOnUploadReady<AutoRecordCubit, AutoRecordState>(
              pinnedItemPublicId: widget.task.pinnedItemPublicId,
              syncEngine: widget.syncEngine,
            ),
      ),
    );
  }
}

class _PersonalIntroductionBody extends StatelessWidget {
  const _PersonalIntroductionBody({required this.task});

  final TaskView task;

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
              instruction: _instructionText(
                task.prepSeconds,
                task.responseSeconds,
              ),
              stimulus: SingleChildScrollView(
                child: Text(task.promptText ?? ''),
              ),
              response: AutoRecordStatusCard(
                task: task,
                recordingState: state,
                snapshot: snapshot,
              ),
            );
          },
        );
      },
    );
  }

  // 2-variable template (task.prepSeconds then task.responseSeconds) —
  // matches DescribeImageScreen's `_instructionText` shape, NOT
  // ReadAloudScreen's single-variable one (which reuses responseSeconds
  // for both slots). Getting this shape wrong would silently produce "In
  // 30 seconds..." instead of "In 25 seconds..." for the fixture's values.
  String _instructionText(int prepSeconds, int responseSeconds) {
    return '${SpeakingWritingStrings.personalIntroductionInstructionPrefix}$prepSeconds'
        '${SpeakingWritingStrings.personalIntroductionInstructionMiddle}$responseSeconds'
        '${SpeakingWritingStrings.personalIntroductionInstructionSuffix}';
  }
}
