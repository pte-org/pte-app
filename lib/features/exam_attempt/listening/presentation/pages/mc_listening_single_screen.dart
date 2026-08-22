import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/mc_listening_single_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/mc_listening_single_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_audio_bar.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_task_header_banner.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_task_header_labels.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/listening_option_list.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// `StatelessWidget` + `BlocProvider` (mirrors `McReadingSingleScreen`, not
/// the StatefulWidget shape Phase 2 uses) — no `TextEditingController`
/// here, so `BlocProvider` alone handles cubit disposal on unmount
/// (phase-03 Design Constraints).
class McListeningSingleScreen extends StatelessWidget {
  const McListeningSingleScreen({
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
      create: (_) => McListeningSingleCubit(
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
            child: BlocBuilder<McListeningSingleCubit, McListeningSingleState>(
              builder: (context, state) {
                return Column(
                  children: [
                    ExamTaskHeaderBanner(title: listeningTaskHeaderTitle(task.taskType)),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    ListeningAudioBar(hasFinishedPlaying: state.hasFinishedPlaying),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    Expanded(
                      child: ListeningOptionList(
                        options: task.options ?? const [],
                        selectedOrderIndex: state.selectedOrderIndex,
                        onChanged: (orderIndex) => context.read<McListeningSingleCubit>().selectOption(orderIndex),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<McListeningSingleCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
