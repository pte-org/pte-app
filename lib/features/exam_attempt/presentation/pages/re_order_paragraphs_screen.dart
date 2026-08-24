import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/task_view.dart';
import '../cubit/re_order_paragraphs_cubit.dart';
import '../widgets/exam_scaffold.dart';
import '../widgets/re_order_paragraphs_list.dart';
import '../widgets/reading_task_header_banner.dart';
import '../widgets/reading_task_header_labels.dart';
import '../widgets/task_advance_button.dart';

/// Renders inside the shared exam shell — single scrollable column, no
/// `ReadingPassageLayout` split (there's no separate options pane distinct
/// from the reorderable list itself; reading-task-types Phase 4 Design
/// Constraints).
class ReOrderParagraphsScreen extends StatelessWidget {
  const ReOrderParagraphsScreen({
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
      create: (_) => ReOrderParagraphsCubit(
        outboxDao: outboxDao,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        initialOrder: task.options ?? const [],
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: Column(
            children: [
              ReadingTaskHeaderBanner(
                title: readingTaskHeaderTitle(task.taskType),
                instruction: readingTaskInstruction(task.taskType),
              ),
              const Expanded(child: ReOrderParagraphsList()),
            ],
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<ReOrderParagraphsCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
