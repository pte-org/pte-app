import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/task_view.dart';
import '../cubit/mc_reading_single_cubit.dart';
import '../widgets/exam_scaffold.dart';
import '../widgets/mc_option_list.dart';
import '../widgets/reading_passage_layout.dart';
import '../widgets/reading_task_header_banner.dart';
import '../widgets/reading_task_header_labels.dart';
import '../widgets/task_advance_button.dart';

/// Renders inside Phase 4's shared shell as the shell's injected content
/// region — builds no top/bottom chrome of its own (phase-05 Design
/// Constraints). [ReadingTaskHeaderBanner]/[ReadingPassageLayout] are an
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
              ReadingTaskHeaderBanner(
                title: readingTaskHeaderTitle(task.taskType),
                instruction: readingTaskInstruction(task.taskType),
              ),
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
