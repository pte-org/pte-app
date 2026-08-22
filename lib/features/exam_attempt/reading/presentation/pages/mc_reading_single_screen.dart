import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_single_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/mc_option_list.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/reading_passage_layout.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_task_header_banner.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/reading_task_header_labels.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// Renders inside Phase 4's shared shell as the shell's injected content
/// region — builds no top/bottom chrome of its own (phase-05 Design
/// Constraints). [ExamTaskHeaderBanner]/[ReadingPassageLayout] are an
/// addition inside the body, not a replacement for [ExamScaffold]'s own
/// `ExamAppBar` (reading-task-types Phase 2 Design Constraints).
class McReadingSingleScreen extends StatelessWidget {
  const McReadingSingleScreen({
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
      create: (_) => McReadingSingleCubit(
        outboxDao: outboxDao,
        attemptPublicId: attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
      ),
      child: Builder(
        builder: (innerContext) => ExamScaffold(
          totalTasks: task.totalTasks,
          body: Column(
            children: [
              ExamTaskHeaderBanner(title: readingTaskHeaderTitle(task.taskType)),
              Expanded(
                child: ReadingPassageLayout(
                  passage: SingleChildScrollView(child: Text(task.promptText ?? '')),
                  interactive: McOptionList(options: task.options ?? const []),
                ),
              ),
            ],
          ),
          bottomAction: TaskAdvanceButton(
            cubit: innerContext.read<McReadingSingleCubit>(),
            pinnedItemPublicId: task.pinnedItemPublicId,
            syncEngine: syncEngine,
          ),
        ),
      ),
    );
  }
}
