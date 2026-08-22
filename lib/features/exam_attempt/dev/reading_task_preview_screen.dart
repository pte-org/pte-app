import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../core/storage/dao/pending_media_upload_dao.dart';
import '../../../core/sync/media_upload_coordinator.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/audio_recorder_service.dart';
import '../domain/task_view.dart';
import '../presentation/widgets/task_type_dispatcher.dart';
import 'reading_task_fixtures.dart';

/// `kDebugMode`-gated developer screen: pick one of [ReadingTaskFixtures]
/// and render it through the real [TaskTypeDispatcher], so a reading-task
/// screen can be visually verified without depending on backend/authoring
/// content being ready. Never reachable outside a debug build — see
/// `main.dart`'s route registration.
class ReadingTaskPreviewScreen extends StatefulWidget {
  const ReadingTaskPreviewScreen({
    super.key,
    required this.outboxDao,
    required this.syncEngine,
    required this.audioRecorderService,
    required this.mediaDao,
    required this.mediaUploadCoordinator,
  });

  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioRecorderService audioRecorderService;
  final PendingMediaUploadDao mediaDao;
  final MediaUploadCoordinator mediaUploadCoordinator;

  @override
  State<ReadingTaskPreviewScreen> createState() => _ReadingTaskPreviewScreenState();
}

class _ReadingTaskPreviewScreenState extends State<ReadingTaskPreviewScreen> {
  TaskView? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      // No real attempt backs this preview, so TaskAdvanceButton's
      // NextTaskRequested is a no-op against ExamAttemptBloc and its
      // loading spinner never clears — this floating back button is the
      // only way out of a selected task in preview mode.
      return Stack(
        children: [
          TaskTypeDispatcher(
            task: selected,
            attemptPublicId: 'dev-preview-attempt',
            outboxDao: widget.outboxDao,
            syncEngine: widget.syncEngine,
            audioRecorderService: widget.audioRecorderService,
            mediaDao: widget.mediaDao,
            mediaUploadCoordinator: widget.mediaUploadCoordinator,
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.small(
                  heroTag: 'dev-reading-preview-back',
                  onPressed: () => setState(() => _selected = null),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.devReadingPreviewTitle)),
      body: ListView(
        children: [
          for (final task in ReadingTaskFixtures.all)
            ListTile(title: Text(task.taskType), onTap: () => setState(() => _selected = task)),
          ListTile(
            title: const Text(AppStrings.devReadingPreviewBlankGroupsUnavailableLabel),
            onTap: () => setState(() => _selected = ReadingTaskFixtures.fillBlanksReadingWritingUnavailable),
          ),
        ],
      ),
    );
  }
}
