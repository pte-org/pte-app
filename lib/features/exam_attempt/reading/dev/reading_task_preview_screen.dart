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
import 'package:pte_app/features/exam_attempt/reading/dev/reading_task_fixtures.dart';
import 'package:pte_app/features/exam_attempt/reading/constants/reading_strings.dart';

/// `kDebugMode`-gated developer screen: pick one of [ReadingTaskFixtures]
/// and render it through the real [TaskTypeDispatcher], so a reading-task
/// screen can be visually verified without depending on backend/authoring
/// content being ready. Never reachable outside a debug build — see
/// `main.dart`'s route registration.
///
/// [examAttemptBloc] is provided as an ancestor because every screen
/// `TaskTypeDispatcher` renders is wrapped in `ExamScaffold` → `ExamAppBar`,
/// which reads `BlocSelector<ExamAttemptBloc, ...>` for the timer display —
/// without this, selecting any fixture throws
/// "Could not find the correct `Provider<ExamAttemptBloc>`" instead of
/// rendering. The bloc's default `AttemptIdle` state makes `ExamAppBar`
/// render nothing (no crash, just no timer bar), which is correct for a
/// preview with no real timer running.
class ReadingTaskPreviewScreen extends StatefulWidget {
  const ReadingTaskPreviewScreen({
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
  State<ReadingTaskPreviewScreen> createState() => _ReadingTaskPreviewScreenState();
}

class _ReadingTaskPreviewScreenState extends State<ReadingTaskPreviewScreen> {
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
          DevPreviewBackButton(onPressed: () => setState(() => _selected = null)),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text(ReadingStrings.devReadingPreviewTitle)),
      body: ListView(
        children: [
          for (final task in ReadingTaskFixtures.all)
            ListTile(title: Text(task.taskType), onTap: () => setState(() => _selected = task)),
          ListTile(
            title: const Text(ReadingStrings.devReadingPreviewBlankGroupsUnavailableLabel),
            onTap: () => setState(() => _selected = ReadingTaskFixtures.fillBlanksReadingWritingUnavailable),
          ),
        ],
      ),
    );
  }
}
