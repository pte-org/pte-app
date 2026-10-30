import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/widgets/templates/exam_task_frame.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import '../../constants/reading_strings.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_drag_drop_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/fill_blanks_drag_drop_body.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';
import 'package:pte_app/core/utils/task_instruction_resolver.dart';

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
    this.initialAnswerPayload,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final String? initialAnswerPayload;

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
        initialPayload: initialAnswerPayload,
        options: task.options ?? const [],
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: ExamTaskFrame(
            title: TaskTypeMeta.forTaskType(task.taskType)?.title ?? task.title,
            maxWidth: AppDimensions.readingWorkstationMaxWidth,
            instruction: resolveTaskInstruction(
              apiInstruction: task.taskTypeInstruction,
              meta: TaskTypeMeta.forTaskType(task.taskType),
              fallback: ReadingStrings.dragDropInstruction,
            ),
            body: FillBlanksDragDropBody(task: task),
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
