import 'package:flutter/material.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
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
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/describe_image_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/read_aloud_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/repeat_sentence_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/retell_lecture_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/summarize_spoken_text_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/pages/write_essay_screen.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/pages/write_from_dictation_screen.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

const String _taskTypeMcReadingSingle = 'MC_READING_SINGLE';
const String _taskTypeMcReadingMultiple = 'MC_READING_MULTIPLE';
const String _taskTypeReOrderParagraphs = 'RE_ORDER_PARAGRAPHS';
const String _taskTypeFillBlanksReading = 'FILL_BLANKS_READING';
const String _taskTypeFillBlanksReadingWriting = 'FILL_BLANKS_READING_WRITING';
const String _taskTypeWriteEssay = 'WRITE_ESSAY';
const String _taskTypeReadAloud = 'READ_ALOUD';
const String _taskTypeRepeatSentence = 'REPEAT_SENTENCE';
const String _taskTypeDescribeImage = 'DESCRIBE_IMAGE';
const String _taskTypeRetellLecture = 'RE_TELL_LECTURE';

// Listening — string constants verified against
// `pte-api/services/authoring/.../PteTaskType.java` (phase-01 Design
// Constraints).
const String _taskTypeWriteFromDictation = 'WRITE_FROM_DICTATION';
const String _taskTypeSummarizeSpokenText = 'SUMMARIZE_SPOKEN_TEXT';
const String _taskTypeHighlightIncorrectWords = 'HIGHLIGHT_INCORRECT_WORDS';
const String _taskTypeFillBlanksListening = 'FILL_BLANKS_LISTENING';
const String _taskTypeMcListeningMultiple = 'MC_LISTENING_MULTIPLE';
const String _taskTypeMcListeningSingle = 'MC_LISTENING_SINGLE';
const String _taskTypeSelectMissingWord = 'SELECT_MISSING_WORD';
const String _taskTypeHighlightCorrectSummary = 'HIGHLIGHT_CORRECT_SUMMARY';

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
    required this.audioPlayerService,
  });

  final TaskView task;
  final String attemptPublicId;
  final AnswerOutboxDao outboxDao;
  final SyncEngine syncEngine;
  final AudioRecorderService audioRecorderService;
  final PendingMediaUploadDao mediaDao;
  final MediaUploadCoordinator mediaUploadCoordinator;

  /// Only consumed by listening task types (phase-02 Design Constraints) —
  /// unused by Reading/Speaking/Writing screens, same pattern as
  /// `audioRecorderService` being unused outside `READ_ALOUD`.
  final AudioPlayerService audioPlayerService;

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
      _taskTypeMcReadingMultiple => McReadingMultipleScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
      ),
      _taskTypeReOrderParagraphs => ReOrderParagraphsScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
      ),
      _taskTypeFillBlanksReading => FillBlanksDragDropScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
      ),
      _taskTypeFillBlanksReadingWriting => FillBlanksDropdownScreen(
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
      _taskTypeRepeatSentence => RepeatSentenceScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        recorder: audioRecorderService,
        mediaDao: mediaDao,
        coordinator: mediaUploadCoordinator,
        syncEngine: syncEngine,
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
      ),
      _taskTypeWriteFromDictation => WriteFromDictationScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
      ),
      _taskTypeSummarizeSpokenText => SummarizeSpokenTextScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
      ),
      _taskTypeMcListeningSingle => McListeningSingleScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
      ),
      _taskTypeMcListeningMultiple => McListeningMultipleScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
      ),
      _taskTypeSelectMissingWord => SelectMissingWordScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
      ),
      _taskTypeHighlightIncorrectWords => HighlightIncorrectWordsScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
      ),
      _taskTypeHighlightCorrectSummary => HighlightCorrectSummaryScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
      ),
      _taskTypeFillBlanksListening => FillBlanksListeningScreen(
        key: key,
        task: task,
        attemptPublicId: attemptPublicId,
        outboxDao: outboxDao,
        syncEngine: syncEngine,
        audioPlayerService: audioPlayerService,
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
    return Center(
      child: Text('${ExamAttemptStrings.unsupportedTaskTypePrefix}$taskType'),
    );
  }
}
