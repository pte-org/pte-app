import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/widgets/components/exam_status_block.dart';
import 'package:pte_app/core/widgets/templates/fill_blanks_template.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_drag_drop_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/fill_blanks_drag_drop_body.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// Renders inside the shared exam shell — single scrollable column, no
/// legacy passage split (reading-task-types Phase 5 Design
/// Constraints).
class FillBlanksDragDropScreen extends StatelessWidget {
  const FillBlanksDragDropScreen({
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
    final gapCount = parseBlankPrompt(
      task.promptText ?? '',
    ).whereType<PromptGapSegment>().length;
    return BlocProvider(
      create: (_) => FillBlanksDragDropCubit(
        outboxDao: outboxDao,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        gapCount: gapCount,
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: FillBlanksTemplate(
            title: TaskTypeMeta.forTaskType(task.taskType)?.title ?? task.title,
            subtitle: task.section,
            instruction:
                TaskTypeMeta.forTaskType(task.taskType)?.instruction ??
                'Drag the words into the correct blanks.',
            stimulus: const ExamStatusBlock(
              title: 'Word bank',
              message: 'Drag each word to the matching blank in the passage.',
            ),
            response: FillBlanksDragDropBody(task: task),
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<FillBlanksDragDropCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
