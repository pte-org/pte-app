import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/audio_listening_status_card.dart';
import 'package:pte_app/core/widgets/templates/multi_select_template.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/mc_listening_multiple_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/mc_listening_multiple_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_multiple_option_list.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// Same `StatelessWidget` + `BlocProvider` shape as
/// `McListeningSingleScreen` (phase-03 Design Constraints).
class McListeningMultipleScreen extends StatelessWidget {
  const McListeningMultipleScreen({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.outboxDao,
    required this.syncEngine,
    required this.audioPlayerService,
    this.initialAnswerPayload,
    this.isPractice = false,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioPlayerService audioPlayerService;
  final String? initialAnswerPayload;
  final bool isPractice;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => McListeningMultipleCubit(
        outboxDao: outboxDao,
        audioPlayerService: audioPlayerService,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        audioSource: task.audioUrl ?? '',
        initialPayload: initialAnswerPayload,
        isPractice: isPractice,
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: BlocBuilder<McListeningMultipleCubit, McListeningMultipleState>(
            builder: (context, state) {
              return MultiSelectTemplate(
                title:
                    TaskTypeMeta.forTaskType(task.taskType)?.title ??
                    task.title,
                subtitle: task.section,
                instruction:
                    TaskTypeMeta.forTaskType(task.taskType)?.instruction ??
                    'Select all the correct responses.',
                stimulus: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AudioListeningStatusCard(
                      statusLabel: !state.hasStartedPlaying
                          ? 'Tap to listen'
                          : state.hasFinishedPlaying
                              ? 'Audio finished'
                              : 'Playing audio...',
                      progress: !state.hasStartedPlaying
                          ? 0.0
                          : state.hasFinishedPlaying
                              ? 1.0
                              : state.progress,
                    ),
                    if (isPractice) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (!state.hasStartedPlaying) {
                            context.read<McListeningMultipleCubit>().startPlayback();
                          } else {
                            context.read<McListeningMultipleCubit>().replayAudio();
                          }
                        },
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(!state.hasStartedPlaying ? 'Tap to listen' : 'Listen again'),
                      ),
                    ],
                  ],
                ),
                response: ListeningMultipleOptionList(
                  options: task.options ?? const [],
                  selectedOrderIndexes: state.selectedOrderIndexes,
                  onToggle: (orderIndex) => context
                      .read<McListeningMultipleCubit>()
                      .toggleOption(orderIndex),
                ),
              );
            },
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<McListeningMultipleCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
