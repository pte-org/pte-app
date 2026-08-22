import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/storage/dao/answer_outbox_dao.dart';
import '../../../core/storage/dao/pending_media_upload_dao.dart';
import '../../../core/sync/media_upload_coordinator.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/audio_recorder_service.dart';
import '../domain/task_view.dart';
import '../domain/timer_service.dart';
import '../presentation/bloc/exam_attempt_bloc.dart';
import '../presentation/bloc/exam_attempt_event.dart';
import '../presentation/bloc/exam_attempt_state.dart';
import '../presentation/widgets/task_type_dispatcher.dart';
import 'dev_attempt_repositories.dart';
import 'reading_task_fixtures.dart';
import 'speaking_writing_task_fixtures.dart';

/// `kDebugMode`-gated developer screen: pick one fixture and render it
/// through the real [TaskTypeDispatcher] — driven by a real, throwaway
/// [ExamAttemptBloc]/[TimerService] pair backed by [DevExamAttemptRepository]
/// et al. (never the app's real `getIt`-registered singletons, never a real
/// backend), so every task-type screen — including the timer bar, phase
/// transitions, and (for `READ_ALOUD`) live auto-record — can be visually
/// verified without depending on backend/authoring content being ready.
/// Never reachable outside a debug build — see `main.dart`'s route
/// registration.
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
  static List<TaskView> get _fixtures => [...ReadingTaskFixtures.all, ...SpeakingWritingTaskFixtures.all];

  late DevExamAttemptRepository _repository;
  late TimerService _timerService;
  late ExamAttemptBloc _bloc;

  @override
  void initState() {
    super.initState();
    _createBloc();
  }

  void _createBloc() {
    _repository = DevExamAttemptRepository(nextTask: _fixtures.first);
    _timerService = TimerService(timerRepository: const DevTimerRepository());
    _bloc = ExamAttemptBloc(
      repository: _repository,
      sessionEntryRepository: const DevSessionEntryRepository(),
      syncEngine: widget.syncEngine,
      timerService: _timerService,
      mediaUploadCoordinator: widget.mediaUploadCoordinator,
    );
  }

  void _selectTask(TaskView task) {
    _repository.nextTask = task;
    _bloc.add(const SessionResolutionRequested(rawInput: 'dev'));
  }

  /// `ExamAttemptBloc` has no "reset a completed/errored attempt" event by
  /// design (a real attempt genuinely can't un-complete) — so returning to
  /// the picker replaces the whole bloc/timer pair with a fresh one instead.
  void _resetToPicker() {
    unawaited(_bloc.close());
    _timerService.dispose();
    setState(_createBloc);
  }

  @override
  void dispose() {
    unawaited(_bloc.close());
    _timerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamAttemptBloc>.value(
      value: _bloc,
      child: BlocBuilder<ExamAttemptBloc, ExamAttemptState>(
        builder: (context, state) {
          return switch (state) {
            final AttemptInProgress s => TaskTypeDispatcher(
              key: ValueKey(s.task.pinnedItemPublicId),
              task: s.task,
              attemptPublicId: s.attemptPublicId,
              outboxDao: widget.outboxDao,
              syncEngine: widget.syncEngine,
              audioRecorderService: widget.audioRecorderService,
              mediaDao: widget.mediaDao,
              mediaUploadCoordinator: widget.mediaUploadCoordinator,
            ),
            AttemptStarting() => const Scaffold(body: Center(child: CircularProgressIndicator())),
            AttemptCompleted() => _DevPreviewMessage(
              message: AppStrings.devPreviewTaskCompleteLabel,
              onPickAnother: _resetToPicker,
            ),
            AttemptError(:final error) => _DevPreviewMessage(
              message: '${AppStrings.devPreviewErrorPrefix}$error',
              onPickAnother: _resetToPicker,
            ),
            AttemptIdle() => _FixturePicker(onSelected: _selectTask),
          };
        },
      ),
    );
  }
}

class _FixturePicker extends StatelessWidget {
  const _FixturePicker({required this.onSelected});

  final ValueChanged<TaskView> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.devTaskPreviewTitle)),
      body: ListView(
        children: [
          for (final task in _ReadingTaskPreviewScreenState._fixtures)
            ListTile(title: Text('${task.section} — ${task.taskType}'), onTap: () => onSelected(task)),
          ListTile(
            title: const Text(AppStrings.devReadingPreviewBlankGroupsUnavailableLabel),
            onTap: () => onSelected(ReadingTaskFixtures.fillBlanksReadingWritingUnavailable),
          ),
        ],
      ),
    );
  }
}

class _DevPreviewMessage extends StatelessWidget {
  const _DevPreviewMessage({required this.message, required this.onPickAnother});

  final String message;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spacingMedium),
              ElevatedButton(onPressed: onPickAnother, child: const Text(AppStrings.devPreviewPickAnotherLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
