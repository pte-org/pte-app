import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_advance_on_upload_ready.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_record_timer_bridge_mixin.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';

/// Mock-only sub-stage split within the shared `prep` window (same shape as
/// `RepeatSentenceScreen`'s split): `_preListenSeconds` (3s) is unchanged
/// from Repeat Sentence, `_preRecordSeconds` is 10s (not 3s). Audio-playing
/// duration is whatever remains: `prepSeconds - _preListenSeconds -
/// _preRecordSeconds` (57s when `prepSeconds = 70`).
const int _preListenSeconds = 3;
const int _preRecordSeconds = 10;

/// Renders inside the shared exam shell as its injected content region.
/// Structurally mirrors `RepeatSentenceScreen` exactly (same
/// [AutoRecordCubit] lifecycle, same [AutoRecordTimerBridgeMixin] bridge,
/// same fully-automatic advance, same [AudioPromptRecordBody]-shared 2-card
/// layout) — only the sub-stage constants and instruction text differ.
class RetellLectureScreen extends StatefulWidget {
  const RetellLectureScreen({
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
  State<RetellLectureScreen> createState() => _RetellLectureScreenState();
}

class _RetellLectureScreenState extends State<RetellLectureScreen>
    with AutoRecordTimerBridgeMixin<RetellLectureScreen> {
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
        body: _RetellLectureBody(task: widget.task),
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

class _RetellLectureBody extends StatelessWidget {
  const _RetellLectureBody({required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    return AudioPromptRecordBody(
      task: task,
      preListenSeconds: _preListenSeconds,
      preRecordSeconds: _preRecordSeconds,
      instructionText: _instructionText(task.responseSeconds),
    );
  }

  // Interpolates the local `_preRecordSeconds` sub-stage constant (10), not
  // `task.prepSeconds` (70, the combined audio+prep total) — the mockup's
  // "in 10 seconds" refers to the pre-record "chuẩn bị" window alone.
  String _instructionText(int responseSeconds) {
    return '${SpeakingWritingStrings.retellLectureInstructionPrefix}$_preRecordSeconds'
        '${SpeakingWritingStrings.retellLectureInstructionMiddle}$responseSeconds'
        '${SpeakingWritingStrings.retellLectureInstructionSuffix}';
  }
}
