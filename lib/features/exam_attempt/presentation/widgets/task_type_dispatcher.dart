import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/task_view.dart';
import '../pages/mc_reading_single_screen.dart';
import '../pages/write_essay_screen.dart';

const String _taskTypeMcReadingSingle = 'MC_READING_SINGLE';
const String _taskTypeWriteEssay = 'WRITE_ESSAY';

/// Switches on `TaskView.taskType` to select the right task screen.
/// `READ_ALOUD` (Phase 6) is not yet built — surfaced as an explicit
/// unsupported-type placeholder rather than a silent blank screen, so
/// Phase 6 has this exact seam to plug into (phase-05 Steps).
class TaskTypeDispatcher extends StatelessWidget {
  const TaskTypeDispatcher({
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
    return switch (task.taskType) {
      _taskTypeMcReadingSingle => McReadingSingleScreen(
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
      ),
      _taskTypeWriteEssay => WriteEssayScreen(
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
      ),
      _ => _UnsupportedTaskTypePlaceholder(taskType: task.taskType),
    };
  }
}

class _UnsupportedTaskTypePlaceholder extends StatelessWidget {
  const _UnsupportedTaskTypePlaceholder({required this.taskType});

  final String taskType;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('${AppStrings.unsupportedTaskTypePrefix}$taskType'));
  }
}
