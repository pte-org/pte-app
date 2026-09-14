import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/core/widgets/components/exam_status_block.dart';
import 'package:pte_app/core/widgets/templates/fill_blanks_template.dart';
import 'package:pte_app/core/widgets/status_banner.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/fill_blanks_dropdown_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/fill_blanks_dropdown_body.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';
import 'package:pte_app/features/exam_attempt/reading/constants/reading_strings.dart';

/// Renders inside the shared exam shell — single scrollable column, no
/// legacy passage split. Falls back to [StatusBanner] when
/// `task.blankGroups` is null/empty (expected until this plan's backend
/// phases ship — reading-task-types Phase 6 Design Constraints).
class FillBlanksDropdownScreen extends StatelessWidget {
  const FillBlanksDropdownScreen({
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
    final blankGroups = task.blankGroups;
    final contentAvailable = blankGroups != null && blankGroups.isNotEmpty;

    // A cubit (possibly zero-length) is always created so `TaskAdvanceButton`
    // is always present — a student must never be stuck unable to advance
    // just because this task's content hasn't loaded (mirrors this app's
    // "never a server-trusted gate on advancing" principle elsewhere).
    return BlocProvider(
      create: (_) => FillBlanksDropdownCubit(
        outboxDao: outboxDao,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        blankGroupCount: blankGroups?.length ?? 0,
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: FillBlanksTemplate(
            title: TaskTypeMeta.forTaskType(task.taskType)?.title ?? task.title,
            subtitle: task.section,
            instruction:
                TaskTypeMeta.forTaskType(task.taskType)?.instruction ??
                'Select the best word for each blank.',
            stimulus: const ExamStatusBlock(
              title: 'Reading passage',
              message: 'Select one option for every blank.',
            ),
            response: contentAvailable
                ? FillBlanksDropdownBody(task: task)
                : const StatusBanner(
                    icon: Icons.hourglass_empty,
                    title: ReadingStrings.fillBlanksContentUnavailableTitle,
                    message: ReadingStrings.fillBlanksContentUnavailableMessage,
                  ),
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<FillBlanksDropdownCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
