import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../../core/storage/dao/pending_media_upload_dao.dart';
import '../../../../core/sync/media_upload_coordinator.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/audio_recorder_service.dart';
import '../../domain/task_view.dart';
import '../pages/mc_reading_single_screen.dart';
import '../pages/read_aloud_screen.dart';
import '../pages/write_essay_screen.dart';

const String _taskTypeMcReadingSingle = 'MC_READING_SINGLE';
const String _taskTypeWriteEssay = 'WRITE_ESSAY';
const String _taskTypeReadAloud = 'READ_ALOUD';

/// Switches on `TaskView.taskType` to select the right task screen.
class TaskTypeDispatcher extends StatelessWidget {
  const TaskTypeDispatcher({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.outboxDao,
    required this.syncEngine,
    required this.audioRecorderService,
    required this.mediaDao,
    required this.mediaUploadCoordinator,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioRecorderService audioRecorderService;
  final PendingMediaUploadDao mediaDao;
  final MediaUploadCoordinator mediaUploadCoordinator;

  @override
  Widget build(BuildContext context) {
    // Keyed on pinnedItemPublicId so Flutter tears down and recreates the
    // Element (and therefore the screen's cubit/controller) on every task
    // change — including consecutive tasks of the same type, which would
    // otherwise reuse the same Element and silently carry the previous
    // task's cubit/draft state (and its now-stale pinnedItemPublicId) into
    // the new task (phase-05 Design Constraints: "a stale value here would
    // silently misfile an answer against the wrong task").
    final key = ValueKey(task.pinnedItemPublicId);
    return switch (task.taskType) {
      _taskTypeMcReadingSingle => McReadingSingleScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
      ),
      _taskTypeWriteEssay => WriteEssayScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
      ),
      _taskTypeReadAloud => ReadAloudScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
        syncEngine: syncEngine,
      ),
      _ => _UnsupportedTaskTypePlaceholder(key: key, taskType: task.taskType),
    };
  }
}

class _UnsupportedTaskTypePlaceholder extends StatelessWidget {
  const _UnsupportedTaskTypePlaceholder({super.key, required this.taskType});

  final String taskType;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('${AppStrings.unsupportedTaskTypePrefix}$taskType'));
  }
}
