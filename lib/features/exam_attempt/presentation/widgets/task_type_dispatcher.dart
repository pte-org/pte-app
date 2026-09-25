import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/fill_blanks_drag_drop_screen.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/fill_blanks_dropdown_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/fill_blanks_listening_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/highlight_correct_summary_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/highlight_incorrect_words_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/mc_listening_multiple_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/mc_listening_single_screen.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/mc_reading_multiple_screen.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/mc_reading_single_screen.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/re_order_paragraphs_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/select_missing_word_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/answer_short_question_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/describe_image_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/personal_introduction_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/read_aloud_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/repeat_sentence_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/respond_to_a_situation_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/retell_lecture_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/summarize_group_discussion_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/summarize_spoken_text_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/summarize_written_text_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/write_essay_v2_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/write_from_dictation_screen.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

const String _taskTypeMcReadingSingle = 'MC_READING_SINGLE';
const String _taskTypeMcReadingMultiple = 'MC_READING_MULTIPLE';
const String _taskTypeReOrderParagraphs = 'RE_ORDER_PARAGRAPHS';
const String _taskTypeFillBlanksReading =
    TaskTypeCodes.fillInTheBlanksDragAndDrop;
const String _taskTypeFillBlanksReadingWriting =
    TaskTypeCodes.fillInTheBlanksDropdown;
const String _taskTypeWriteEssay = 'WRITE_ESSAY';
const String _taskTypeSummarizeWrittenText = 'SUMMARIZE_WRITTEN_TEXT';
const String _taskTypePersonalIntroduction = 'PERSONAL_INTRODUCTION';
const String _taskTypeReadAloud = 'READ_ALOUD';
// Additional speaking tasks (from origin/dev).
const String _taskTypeRepeatSentence = 'REPEAT_SENTENCE';
const String _taskTypeDescribeImage = 'DESCRIBE_IMAGE';
const String _taskTypeRetellLecture = 'RE_TELL_LECTURE';
const String _taskTypeAnswerShortQuestion = 'ANSWER_SHORT_QUESTION';
const String _taskTypeSummarizeGroupDiscussion = 'SUMMARIZE_GROUP_DISCUSSION';
const String _taskTypeRespondToASituation = 'RESPOND_TO_A_SITUATION';

// Listening — string constants verified against
// `pte-api/services/authoring/.../PteTaskType.java` (phase-01 Design
// Constraints).
const String _taskTypeWriteFromDictation = 'WRITE_FROM_DICTATION';
const String _taskTypeSummarizeSpokenText = 'SUMMARIZE_SPOKEN_TEXT';
const String _taskTypeHighlightIncorrectWords = 'HIGHLIGHT_INCORRECT_WORDS';
const String _taskTypeFillBlanksListening = TaskTypeCodes.fillInTheBlanksTypeIn;
const String _taskTypeMcListeningMultiple = 'MC_LISTENING_MULTIPLE';
const String _taskTypeMcListeningSingle = 'MC_LISTENING_SINGLE';
const String _taskTypeSelectMissingWord = 'SELECT_MISSING_WORD';
const String _taskTypeHighlightCorrectSummary = 'HIGHLIGHT_CORRECT_SUMMARY';

/// Switches on `TaskView.taskType` to select the right task screen.
class TaskTypeDispatcher extends StatefulWidget {
  const TaskTypeDispatcher({
    super.key,
    required this.task,
    required this.attemptPublicId,
    required this.outboxDao,
    required this.syncEngine,
    required this.audioRecorderService,
    required this.mediaDao,
    required this.mediaUploadCoordinator,
    required this.audioPlayerService,
    required this.audioPromptRepository,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioRecorderService audioRecorderService;
  final PendingMediaUploadDao mediaDao;
  final MediaUploadCoordinator mediaUploadCoordinator;

  /// Consumed by listening task types AND the 5 audio-prompt Speaking task
  /// types (Repeat Sentence, Retell Lecture, Answer Short Question,
  /// Summarize Group Discussion, Respond to a Situation) as of
  /// plans/phat-speaking-audio-prompt-e2e — unused by every other screen,
  /// same pattern as `audioRecorderService` being unused outside the
  /// auto-record screens.
  final AudioPlayerService audioPlayerService;

  /// Only consumed by the same 5 audio-prompt Speaking task types above —
  /// resolves the on-demand `/audio` endpoint's playable URL
  /// (plans/phat-speaking-audio-prompt-e2e).
  final AudioPromptRepository audioPromptRepository;

  @override
  State<TaskTypeDispatcher> createState() => _TaskTypeDispatcherState();
}

class _TaskTypeDispatcherState extends State<TaskTypeDispatcher> {
  late Future<String?> _answerPayloadFuture;

  @override
  void initState() {
    super.initState();
    _answerPayloadFuture = _readAnswerPayload();
  }

  @override
  void didUpdateWidget(covariant TaskTypeDispatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attemptPublicId != widget.attemptPublicId ||
        oldWidget.task.pinnedItemPublicId != widget.task.pinnedItemPublicId) {
      _answerPayloadFuture = _readAnswerPayload();
    }
  }

  Future<String?> _readAnswerPayload() async {
    final answer = await widget.outboxDao.getAnswer(
      widget.attemptPublicId,
      widget.task.pinnedItemPublicId,
    );
    return answer?.payload;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _answerPayloadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40),
                      const SizedBox(height: 12),
                      const Text('Unable to restore this task answer.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(() {
                          _answerPayloadFuture = _readAnswerPayload();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return _buildTask(context, snapshot.data);
      },
    );
  }

  Widget _buildTask(BuildContext context, String? initialAnswerPayload) {
    final task = widget.task;
    final attemptPublicId = widget.attemptPublicId;
    final outboxDao = widget.outboxDao;
    final syncEngine = widget.syncEngine;
    final audioRecorderService = widget.audioRecorderService;
    final mediaDao = widget.mediaDao;
    final mediaUploadCoordinator = widget.mediaUploadCoordinator;
    final audioPlayerService = widget.audioPlayerService;
    final audioPromptRepository = widget.audioPromptRepository;

    // Keyed on attempt + pinned item so Flutter tears down and recreates the
    // Element (and therefore the screen's cubit/controller) on every task
    // change — including consecutive tasks of the same type, which would
    // otherwise reuse the same Element and silently carry the previous
    // task's cubit/draft state (and its now-stale pinnedItemPublicId) into
    // the new task (phase-05 Design Constraints: "a stale value here would
    // silently misfile an answer against the wrong task").
    final key = ValueKey('$attemptPublicId:${task.pinnedItemPublicId}');
    final resolution = TaskTypeRendererRegistry.resolve(
      taskTypeCode: task.taskTypeCode,
      legacyTaskType: task.taskType,
      runtime: task.runtime,
    );
    final registration = resolution.registration;
    if (registration == null) {
      return _UnsupportedTaskScreen(key: key, resolution: resolution);
    }

    return switch (registration.taskTypeCode) {
      _taskTypeMcReadingSingle => McReadingSingleScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeMcReadingMultiple => McReadingMultipleScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeReOrderParagraphs => ReOrderParagraphsScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeFillBlanksReading => FillBlanksDragDropScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeFillBlanksReadingWriting => FillBlanksDropdownScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeWriteEssay => WriteEssayV2Screen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeSummarizeWrittenText => SummarizeWrittenTextScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypePersonalIntroduction => PersonalIntroductionScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
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
      _taskTypeRepeatSentence => RepeatSentenceScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        audioPromptRepository: audioPromptRepository,
      ),
      _taskTypeDescribeImage => DescribeImageScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
        syncEngine: syncEngine,
      ),
      _taskTypeRetellLecture => RetellLectureScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        audioPromptRepository: audioPromptRepository,
      ),
      _taskTypeAnswerShortQuestion => AnswerShortQuestionScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        audioPromptRepository: audioPromptRepository,
      ),
      _taskTypeSummarizeGroupDiscussion => SummarizeGroupDiscussionScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        audioPromptRepository: audioPromptRepository,
      ),
      _taskTypeRespondToASituation => RespondToASituationScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        audioPromptRepository: audioPromptRepository,
      ),
      _taskTypeWriteFromDictation => WriteFromDictationScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeSummarizeSpokenText => SummarizeSpokenTextScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeMcListeningSingle => McListeningSingleScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeMcListeningMultiple => McListeningMultipleScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeSelectMissingWord => SelectMissingWordScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeHighlightIncorrectWords => HighlightIncorrectWordsScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeHighlightCorrectSummary => HighlightCorrectSummaryScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _taskTypeFillBlanksListening => FillBlanksListeningScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
        initialAnswerPayload: initialAnswerPayload,
      ),
      _ => _UnsupportedTaskScreen(key: key, resolution: resolution),
    };
  }
}

/// A terminal delivery state for an unsupported frozen task. It deliberately
/// has no answer control and no next-task action: advancing would silently
/// change the exam's item count and misfile the student's attempt.
class _UnsupportedTaskScreen extends StatelessWidget {
  const _UnsupportedTaskScreen({super.key, required this.resolution});

  final TaskTypeResolution resolution;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update_alt, size: 48),
                const SizedBox(height: 16),
                Text(
                  ExamAttemptStrings.unsupportedTaskTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  ExamAttemptStrings.unsupportedTaskMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ExamAttemptStrings.unsupportedTaskContactHost,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
