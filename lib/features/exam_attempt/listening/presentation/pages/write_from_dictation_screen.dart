import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/write_from_dictation_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/write_from_dictation_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_audio_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_task_header_banner.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_task_header_labels.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_word_count_label.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';
import 'package:pte_app/features/exam_attempt/listening/constants/listening_strings.dart';

/// StatefulWidget (mirrors `write_essay_screen.dart`, not `McReadingSingleScreen`)
/// because it owns a `TextEditingController` — the cubit never touches it
/// (phase-02 Design Constraints, corrected during red-team review).
class WriteFromDictationScreen extends StatefulWidget {
  const WriteFromDictationScreen({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.outboxDao,
    required this.syncEngine,
    required this.audioPlayerService,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioPlayerService audioPlayerService;

  @override
  State<WriteFromDictationScreen> createState() => _WriteFromDictationScreenState();
}

class _WriteFromDictationScreenState extends State<WriteFromDictationScreen> {
  late final WriteFromDictationCubit _cubit;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _cubit = WriteFromDictationCubit(
      outboxDao: widget.outboxDao,
      audioPlayerService: widget.audioPlayerService,
      attemptPublicId: widget.attemptPublicId,
      pinnedItemPublicId: widget.task.pinnedItemPublicId,
      audioSource: widget.task.audioPromptRef ?? '',
    );
    _controller = TextEditingController()..addListener(() => _cubit.draftChanged(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: ExamScaffold(
        totalTasks: widget.task.totalTasks,
        body: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: BlocBuilder<WriteFromDictationCubit, WriteFromDictationState>(
            builder: (context, state) {
              return Column(
                children: [
                  ExamTaskHeaderBanner(title: listeningTaskHeaderTitle(widget.task.taskType)),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  ListeningAudioBar(hasFinishedPlaying: state.hasFinishedPlaying),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  const Text(ListeningStrings.writeFromDictationPrompt),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(labelText: ListeningStrings.writeFromDictationFieldLabel),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  ListeningWordCountLabel(
                    wordCount: state.wordCount,
                    minWordCount: widget.task.minWordCount,
                    maxWordCount: widget.task.maxWordCount,
                  ),
                ],
              );
            },
          ),
        ),
        bottomAction: TaskAdvanceButton(
          cubit: _cubit,
          pinnedItemPublicId: widget.task.pinnedItemPublicId,
          syncEngine: widget.syncEngine,
        ),
      ),
    );
  }
}
