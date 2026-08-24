import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/transcript_words.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_incorrect_words_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_incorrect_words_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_audio_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_task_header_banner.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_task_header_labels.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/word_selection_list.dart';

/// `StatelessWidget` + `BlocProvider` — no `TextEditingController`, same
/// reasoning as Phase 3's screens (phase-04 Design Constraints). Words are
/// parsed from `task.promptText` once per build via `splitTranscriptWords`.
class HighlightIncorrectWordsScreen extends StatelessWidget {
  const HighlightIncorrectWordsScreen({
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
  Widget build(BuildContext context) {
    final words = splitTranscriptWords(task.promptText ?? '');
    return BlocProvider(
      create: (_) => HighlightIncorrectWordsCubit(
        outboxDao: outboxDao,
        audioPlayerService: audioPlayerService,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        audioSource: task.audioPromptRef ?? '',
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMedium),
            child: BlocBuilder<HighlightIncorrectWordsCubit, HighlightIncorrectWordsState>(
              builder: (context, state) {
                return Column(
                  children: [
                    ExamTaskHeaderBanner(title: listeningTaskHeaderTitle(task.taskType)),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    ListeningAudioBar(hasFinishedPlaying: state.hasFinishedPlaying),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    Expanded(
                      child: SingleChildScrollView(
                        child: WordSelectionList(
                          words: words,
                          selectedIndices: state.selectedWordIndices,
                          onToggle: (wordIndex) =>
                              context.read<HighlightIncorrectWordsCubit>().toggleWord(wordIndex),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<HighlightIncorrectWordsCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
