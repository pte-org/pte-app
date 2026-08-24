import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../domain/task_view.dart';
import '../cubit/fill_blanks_dropdown_cubit.dart';
import '../widgets/exam_scaffold.dart';
import '../widgets/fill_blanks_dropdown_body.dart';
import '../widgets/reading_content_card.dart';
import '../widgets/reading_task_header_banner.dart';
import '../widgets/reading_task_header_labels.dart';
import '../widgets/task_advance_button.dart';

/// Renders inside the shared exam shell — single scrollable column, no
/// `ReadingPassageLayout` split. Falls back to [StatusBanner] when
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
                    child: contentAvailable
                        ? FillBlanksDropdownBody(task: task)
                        : const StatusBanner(
                            icon: Icons.hourglass_empty,
                            title: AppStrings.fillBlanksContentUnavailableTitle,
                            message: AppStrings.fillBlanksContentUnavailableMessage,
                          ),
                  ),
                ),
              ],
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
