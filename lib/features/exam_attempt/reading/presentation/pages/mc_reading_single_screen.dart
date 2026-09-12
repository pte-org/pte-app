import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/templates/single_select_template.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/cubit/mc_reading_single_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/exam_scaffold.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/widgets/mc_option_list.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_advance_button.dart';

/// Renders inside Phase 4's shared shell as the shell's injected content
/// region — builds no top/bottom chrome of its own (phase-05 Design
/// Constraints). The task header and shared template are an
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
          body: SingleSelectTemplate(
            title: TaskTypeMeta.forTaskType(task.taskType)?.title ?? task.title,
            subtitle: task.section,
            instruction: 'Select the correct response.',
            readingLayout: true,
            stimulus: SingleChildScrollView(child: Text(task.promptText ?? '')),
            response: McOptionList(options: task.options ?? const []),
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
