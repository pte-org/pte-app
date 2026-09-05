import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_advance_on_upload_ready.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_record_timer_bridge_mixin.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';

/// Renders inside the shared exam shell as its injected content region —
/// builds no top/bottom chrome of its own. Structurally mirrors
/// `ReadAloudScreen` exactly (same [AutoRecordCubit] lifecycle, same
/// [AutoRecordTimerBridgeMixin] bridge, same fully-automatic advance) —
/// both now share [AutoRecordCubit]/[AutoRecordState] and the timer-bridge
/// mixin (unified once Describe Image hit this project's 3-occurrence DRY
/// threshold); the body itself (the two always-visible cards) is likewise
/// shared via [AudioPromptRecordBody], unified once Retell Lecture made
/// this the 3rd screen with this exact card shape.
class RepeatSentenceScreen extends StatefulWidget {
  const RepeatSentenceScreen({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.recorder,
    required this.mediaDao,
    required this.coordinator,
    required this.syncEngine,
    required this.audioPlayerService,
    required this.audioPromptRepository,
  });

  final TaskView task;
  final String attemptPublicId;
  final AudioRecorderService recorder;
  final PendingMediaUploadDao mediaDao;
  final MediaUploadCoordinator coordinator;
  final SyncEngine syncEngine;
  final AudioPlayerService audioPlayerService;
  final AudioPromptRepository audioPromptRepository;

  @override
  State<RepeatSentenceScreen> createState() => _RepeatSentenceScreenState();
}

class _RepeatSentenceScreenState extends State<RepeatSentenceScreen>
    with AutoRecordTimerBridgeMixin<RepeatSentenceScreen> {
  late final AutoRecordCubit _cubit;
  late final AudioPromptCubit _audioPromptCubit;

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
    _audioPromptCubit = AudioPromptCubit(
      repository: widget.audioPromptRepository,
      player: widget.audioPlayerService,
      task: widget.task,
      attemptPublicId: widget.attemptPublicId,
      // Server-owned as of plans/phat-speaking-dynamic-prep-timing — never
      // null here by construction, since exam-delivery only ever pins a
      // REPEAT_SENTENCE item with both populated (Phase 2's dynamic-prep
      // branch requires them to compute prepSeconds in the first place).
      preListenSeconds: widget.task.preListenSeconds!,
      preRecordSeconds: widget.task.preRecordSeconds!,
    );
    startAutoRecordBridge(
      task: widget.task,
      cubit: _cubit,
      audioPromptCubit: _audioPromptCubit,
    );
  }

  @override
  void dispose() {
    disposeAutoRecordBridge();
    unawaited(_cubit.close());
    unawaited(_audioPromptCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _audioPromptCubit),
      ],
      child: ExamScaffold(
        totalTasks: widget.task.totalTasks,
        body: _RepeatSentenceBody(task: widget.task),
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

class _RepeatSentenceBody extends StatelessWidget {
  const _RepeatSentenceBody({required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    return AudioPromptRecordBody(
      task: task,
      preListenSeconds: task.preListenSeconds!,
      preRecordSeconds: task.preRecordSeconds!,
      instructionText: SpeakingWritingStrings.repeatSentenceInstructionText,
    );
  }
}
