import 'package:flutter/material.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart';
import 'package:pte_app/features/exam_attempt/listening/dev/listening_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/listening/constants/listening_strings.dart';

/// `kDebugMode`-gated developer screen: pick one of [ListeningTaskFixtures]
/// and render it through the real [TaskTypeDispatcher] — mirrors
/// [ReadingTaskPreviewScreen] exactly. Never reachable outside a debug
/// build — see `main.dart`'s route registration.
class ListeningTaskPreviewScreen extends StatefulWidget {
  const ListeningTaskPreviewScreen({
    super.key,
    required this.outboxDao,
    required this.syncEngine,
    required this.audioRecorderService,
    required this.mediaDao,
    required this.mediaUploadCoordinator,
    required this.audioPlayerService,
  });

  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioRecorderService audioRecorderService;
  final PendingMediaUploadDao mediaDao;
  final MediaUploadCoordinator mediaUploadCoordinator;
  final AudioPlayerService audioPlayerService;

  @override
  State<ListeningTaskPreviewScreen> createState() => _ListeningTaskPreviewScreenState();
}

class _ListeningTaskPreviewScreenState extends State<ListeningTaskPreviewScreen> {
  TaskView? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      return TaskTypeDispatcher(
        task: selected,
        attemptPublicId: 'dev-preview-attempt',
        outboxDao: widget.outboxDao,
        syncEngine: widget.syncEngine,
        audioRecorderService: widget.audioRecorderService,
        mediaDao: widget.mediaDao,
        mediaUploadCoordinator: widget.mediaUploadCoordinator,
        audioPlayerService: widget.audioPlayerService,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text(ListeningStrings.devListeningPreviewTitle)),
      body: ListView(
        children: [
          for (final task in ListeningTaskFixtures.all)
            ListTile(title: Text(task.taskType), onTap: () => setState(() => _selected = task)),
        ],
      ),
    );
  }
}
