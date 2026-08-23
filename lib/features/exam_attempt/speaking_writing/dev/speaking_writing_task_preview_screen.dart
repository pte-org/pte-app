import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/dev_preview_back_button.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart';
import 'package:pte_app/features/exam_attempt/reading/dev/speaking_writing_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart';

/// `kDebugMode`-gated developer screen: pick one of [SpeakingWritingTaskFixtures]
/// and render it through the real [TaskTypeDispatcher] — mirrors
/// `ReadingTaskPreviewScreen`/`ListeningTaskPreviewScreen` exactly, including
/// providing [examAttemptBloc] as an ancestor so `ExamAppBar`'s
/// `BlocSelector<ExamAttemptBloc, ...>` resolves instead of throwing (see
/// that class's doc comment). Never reachable outside a debug build — see
/// `main.dart`'s route registration.
///
/// [SpeakingWritingTaskFixtures] previously lived inside
/// `ReadingTaskPreviewScreen`'s picker list (spread in alongside
/// `ReadingTaskFixtures`) — broken out into its own FAB/route/screen so
/// Speaking/Writing tasks are reachable independently of Reading ones.
class SpeakingWritingTaskPreviewScreen extends StatefulWidget {
  const SpeakingWritingTaskPreviewScreen({
    super.key,
    required this.outboxDao,
    required this.syncEngine,
    required this.audioRecorderService,
    required this.mediaDao,
    required this.mediaUploadCoordinator,
    required this.audioPlayerService,
    required this.examAttemptBloc,
  });

  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioRecorderService audioRecorderService;
  final PendingMediaUploadDao mediaDao;
  final MediaUploadCoordinator mediaUploadCoordinator;
  final AudioPlayerService audioPlayerService;
  final ExamAttemptBloc examAttemptBloc;

  @override
  State<SpeakingWritingTaskPreviewScreen> createState() =>
      _SpeakingWritingTaskPreviewScreenState();
}

class _SpeakingWritingTaskPreviewScreenState
    extends State<SpeakingWritingTaskPreviewScreen> {
  TaskView? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      return Stack(
        children: [
          BlocProvider.value(
            value: widget.examAttemptBloc,
            child: TaskTypeDispatcher(
              task: selected,
              attemptPublicId: 'dev-preview-attempt',
              outboxDao: widget.outboxDao,
              syncEngine: widget.syncEngine,
              audioRecorderService: widget.audioRecorderService,
              mediaDao: widget.mediaDao,
              mediaUploadCoordinator: widget.mediaUploadCoordinator,
              audioPlayerService: widget.audioPlayerService,
            ),
          ),
          DevPreviewBackButton(
            onPressed: () => setState(() => _selected = null),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          SpeakingWritingStrings.devSpeakingWritingPreviewTitle,
        ),
      ),
      body: ListView(
        children: [
          for (final task in SpeakingWritingTaskFixtures.all)
            ListTile(
              title: Text(task.taskType),
              onTap: () => setState(() => _selected = task),
            ),
        ],
      ),
    );
  }
}
