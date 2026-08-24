import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_multiple_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/mc_multiple_option_list.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/reading_content_card.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/reading_passage_layout.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_task_header_banner.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/reading_task_header_labels.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// Renders inside the shared exam shell — builds no top/bottom chrome of
/// its own (mirrors `McReadingSingleScreen`, reading-task-types Phase 3).
class McReadingMultipleScreen extends StatelessWidget {
  const McReadingMultipleScreen({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.outboxDao,
    required this.syncEngine,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => McReadingMultipleCubit(
        outboxDao: outboxDao,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: Container(
            color: AppColors.readingPageBackground,
            child: Column(
              children: [
                ExamTaskHeaderBanner(
                  title: readingTaskHeaderTitle(task.taskType),
                  instruction: readingTaskInstruction(task.taskType),
                ),
                Expanded(
                  child: ReadingContentCard(
                    child: ReadingPassageLayout(
                      passage: SingleChildScrollView(child: Text(task.promptText ?? '')),
                      interactive: McMultipleOptionList(options: task.options ?? const []),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<McReadingMultipleCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
