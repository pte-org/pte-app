import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/widgets/components/audio_stimulus_player.dart';
import 'package:pte_app/core/widgets/components/choice_list.dart';
import 'package:pte_app/core/widgets/components/choice_row.dart';
import 'package:pte_app/core/widgets/templates/single_select_template.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/select_missing_word_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/select_missing_word_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// Structurally identical to `McListeningSingleScreen` (phase-03 Design
/// Constraints).
class SelectMissingWordScreen extends StatelessWidget {
  const SelectMissingWordScreen({
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
    return BlocProvider(
      create: (_) => SelectMissingWordCubit(
        outboxDao: outboxDao,
        audioPlayerService: audioPlayerService,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        audioSource: task.audioPromptRef ?? '',
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: BlocBuilder<SelectMissingWordCubit, SelectMissingWordState>(
            builder: (context, state) {
              final options = task.options ?? const [];
              final selected = {
                for (var index = 0; index < options.length; index++)
                  if (options[index].orderIndex == state.selectedOrderIndex)
                    index,
              };
              return SingleSelectTemplate(
                title: task.title,
                subtitle: task.section,
                instruction: 'Select the word that completes the recording.',
                stimulus: AudioStimulusPlayer(
                  label: state.hasFinishedPlaying
                      ? 'Audio finished'
                      : 'Playing audio',
                  playing: !state.hasFinishedPlaying,
                  progress: state.hasFinishedPlaying ? 1 : 0,
                ),
                response: SingleChildScrollView(
                  child: ChoiceList(
                    labels: [for (final option in options) option.text],
                    selectedIndices: selected,
                    mode: ChoiceSelectionMode.single,
                    onTap: (index) => context
                        .read<SelectMissingWordCubit>()
                        .selectOption(options[index].orderIndex),
                  ),
                ),
              );
            },
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<SelectMissingWordCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
