import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/task_view.dart';
import '../cubit/mc_reading_multiple_cubit.dart';
import '../widgets/exam_scaffold.dart';
import '../widgets/mc_multiple_option_list.dart';
import '../widgets/reading_content_card.dart';
import '../widgets/reading_passage_layout.dart';
import '../widgets/reading_task_header_banner.dart';
import '../widgets/reading_task_header_labels.dart';
import '../widgets/task_advance_button.dart';

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
                ReadingTaskHeaderBanner(
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
