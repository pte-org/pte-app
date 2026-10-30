import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/widgets/templates/exam_task_frame.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/re_order_paragraphs_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/re_order_paragraphs_list.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';
import 'package:pte_app/core/utils/task_instruction_resolver.dart';

/// Source and Target share the candidate shell's header and footer.
class ReOrderParagraphsScreen extends StatelessWidget {
  const ReOrderParagraphsScreen({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.outboxDao,
    required this.syncEngine,
    this.initialAnswerPayload,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final String? initialAnswerPayload;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReOrderParagraphsCubit(
        outboxDao: outboxDao,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        initialOrder: task.options ?? const [],
        initialPayload: initialAnswerPayload,
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: ExamTaskFrame(
            title: TaskTypeMeta.forTaskType(task.taskType)?.title ?? task.title,
            instruction: resolveTaskInstruction(
              apiInstruction: task.taskTypeInstruction,
              meta: TaskTypeMeta.forTaskType(task.taskType),
            ),
            body: const ReOrderParagraphsList(),
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
