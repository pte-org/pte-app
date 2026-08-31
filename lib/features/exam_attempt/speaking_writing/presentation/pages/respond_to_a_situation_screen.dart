import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_advance_on_upload_ready.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/auto_record_timer_bridge_mixin.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/instruction_text.dart';

/// Mock-only sub-stage split within the shared `prep` window. Unlike the
/// other `AudioListeningPrepCard`/`RecordedAnswerPrepCard` consumers, this
/// screen's `_preListenSeconds = 20` is itself a merge of two conceptually
/// distinct real-PTE stages — 15s reading the situation text + 5s waiting
/// for the audio to start — collapsed into one combined "Beginning in 20
/// seconds" countdown per explicit user decision (no separate "Reading…"
/// label; the situation text stays visible the whole time regardless of
/// sub-stage, so nothing is lost by not visually distinguishing the two).
/// `_preRecordSeconds = 10`; audio-playing duration is whatever remains:
/// `prepSeconds - _preListenSeconds - _preRecordSeconds` (10s when
/// `prepSeconds = 40`).
const int _preListenSeconds = 20;
const int _preRecordSeconds = 10;

/// Renders inside the shared exam shell as its injected content region.
/// The FIRST Speaking screen combining a persistent situation-text display
/// (`task.promptText`, shown above the cards — unlike `ReadAloudScreen`'s
/// passage-after-card layout) with the [AudioListeningPrepCard]/
/// [RecordedAnswerPrepCard] 2-card system. Does not call
/// [AudioPromptRecordBody] itself — that widget's fixed internal `Column`
/// (`InstructionText` immediately followed by the two cards) can't
/// interleave the situation text between them, so this screen composes the
/// now-public [AudioListeningPrepCard]/[RecordedAnswerPrepCard]/
/// [elapsedPrepSeconds] directly, reusing [AudioPromptRecordBody]'s own
/// `build()` wiring shell (`Padding` → `BlocSelector` → `BlocBuilder`) as
/// its template rather than as a black box. Otherwise structurally
/// identical to `AnswerShortQuestionScreen` (same [AutoRecordCubit]
/// lifecycle, same [AutoRecordTimerBridgeMixin] bridge, same fully-
/// automatic advance).
class RespondToASituationScreen extends StatefulWidget {
  const RespondToASituationScreen({
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
  State<RespondToASituationScreen> createState() =>
      _RespondToASituationScreenState();
}

class _RespondToASituationScreenState extends State<RespondToASituationScreen>
    with AutoRecordTimerBridgeMixin<RespondToASituationScreen> {
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
      preListenSeconds: _preListenSeconds,
      preRecordSeconds: _preRecordSeconds,
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
        body: _RespondToASituationBody(task: widget.task),
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

class _RespondToASituationBody extends StatelessWidget {
  const _RespondToASituationBody({required this.task});

  final TaskView task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: BlocSelector<ExamAttemptBloc, ExamAttemptState, TimerSnapshot?>(
        selector: (state) =>
            state is AttemptInProgress ? state.timerSnapshot : null,
        builder: (context, snapshot) {
          return BlocBuilder<AutoRecordCubit, AutoRecordState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InstructionText(
                    text: SpeakingWritingStrings
                        .respondToASituationInstructionText,
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        task.promptText ?? '',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  AudioListeningPrepCard(
                    task: task,
                    snapshot: snapshot,
                    preListenSeconds: _preListenSeconds,
                    preRecordSeconds: _preRecordSeconds,
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  RecordedAnswerPrepCard(
                    task: task,
                    recordingState: state,
                    snapshot: snapshot,
                    preRecordSeconds: _preRecordSeconds,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
