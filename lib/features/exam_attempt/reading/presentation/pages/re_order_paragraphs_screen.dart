import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/widgets/components/exam_status_block.dart';
import 'package:pte_app/core/widgets/templates/ordering_template.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/re_order_paragraphs_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/re_order_paragraphs_list.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// Renders inside the shared exam shell — single scrollable column, no
/// legacy passage split (there's no separate options pane distinct
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
          body: OrderingTemplate(
            title: TaskTypeMeta.forTaskType(task.taskType)?.title ?? task.title,
            subtitle: task.section,
            instruction:
                TaskTypeMeta.forTaskType(task.taskType)?.instruction ??
                'Re-order the paragraphs into the correct sequence.',
            stimulus: const ExamStatusBlock(
              title: 'Paragraph sequence',
              message: 'Use the handles to arrange the paragraphs.',
            ),
            response: const ReOrderParagraphsList(),
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
