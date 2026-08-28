/// A single reorderable option within a task (e.g. one word-bank tile, one
/// heading choice). `orderIndex` is a decimal string, not an int — matches
/// the same reordering convention used by the outbox's submit payload
/// (`plan.md` Research Summary item 7a), so a UI reorder never needs an
/// integer-reindex pass across every other option.
class TaskOption {
  const TaskOption({required this.text, required this.orderIndex});

  final String text;
  final String orderIndex;

  factory TaskOption.fromJson(Map<String, dynamic> json) {
    return TaskOption(
      text: json['text'] as String,
      // Safely handles both String and legacy int until BE rollout is complete.
      orderIndex: json['orderIndex'].toString(),
    );
  }
}

/// One independently-choosable blank within a `FILL_BLANKS_READING_WRITING`
/// task — its [options] are distinct from every other blank's, unlike the
/// shared word bank [TaskView.options] carries for `FILL_BLANKS_READING`.
class BlankGroup {
  const BlankGroup({required this.blankIndex, required this.options});

  final int blankIndex;
  final List<TaskOption> options;

  factory BlankGroup.fromJson(Map<String, dynamic> json) {
    return BlankGroup(
      blankIndex: json['blankIndex'] as int,
      options: (json['options'] as List<dynamic>)
          .map((option) => TaskOption.fromJson(option as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The full task shape returned by both `startOrResumeAttempt` and
/// `fetchNextTask` (phase-03 Steps). This phase only carries every field
/// through untouched — Phase 4/5/6 are what consume `prepDeadline`/
/// `responseDeadline`/`options` etc.
///
/// [options] is reused across several reading task types beyond its
/// original MC-choice purpose: for `MC_READING_MULTIPLE` it's the checkbox
/// choices, for `FILL_BLANKS_READING` it's the shared drag-and-drop word
/// bank, and for `RE_ORDER_PARAGRAPHS` it's the shuffled paragraph list
/// (`TaskOption.text` = a paragraph's full text, `TaskOption.orderIndex` =
/// its stable correct-position identity — **never** its current on-screen
/// position, which is exactly what the student is rearranging). [options]
/// and [blankGroups] are mutually exclusive per task — only
/// `FILL_BLANKS_READING_WRITING` ever populates [blankGroups], where every
/// blank needs its own distinct option list that a flat [options] list
/// can't express.
class TaskView {
  const TaskView({
    required this.pinnedItemPublicId,
    required this.orderIndex,
    required this.totalTasks,
    required this.section,
    required this.taskType,
    required this.title,
    this.promptText,
    this.audioPromptRef,
    this.imagePromptRef,
    this.minWordCount,
    this.maxWordCount,
    this.options,
    this.blankGroups,
    required this.prepSeconds,
    required this.responseSeconds,
    required this.prepDeadline,
    required this.responseDeadline,
    required this.serverNow,
    this.examEndTime,
  });

  final String pinnedItemPublicId;
  final int orderIndex;
  final int totalTasks;
  final String section;
  final String taskType;
  final String title;
  final String? promptText;
  final String? audioPromptRef;
  final String? imagePromptRef;
  final int? minWordCount;
  final int? maxWordCount;
  final List<TaskOption>? options;
  final List<BlankGroup>? blankGroups;
  final int prepSeconds;
  final int responseSeconds;
  final DateTime prepDeadline;
  final DateTime responseDeadline;
  final DateTime serverNow;

  /// Whole-attempt deadline (`ExamAttempt.startedAt` + every pinned item's
  /// `prepSeconds + responseSeconds`) — distinct from [prepDeadline]/
  /// [responseDeadline], which govern only the current task/section. Null
  /// only for an attempt created before the backend started populating this
  /// field.
  final DateTime? examEndTime;

  factory TaskView.fromJson(Map<String, dynamic> json) {
    return TaskView(
      pinnedItemPublicId: json['pinnedItemPublicId'] as String,
      orderIndex: json['orderIndex'] as int,
      totalTasks: json['totalTasks'] as int,
      section: json['section'] as String,
      taskType: json['taskType'] as String,
      title: json['title'] as String,
      promptText: json['promptText'] as String?,
      audioPromptRef: json['audioPromptRef'] as String?,
      imagePromptRef: json['imagePromptRef'] as String?,
      minWordCount: json['minWordCount'] as int?,
      maxWordCount: json['maxWordCount'] as int?,
      options: (json['options'] as List<dynamic>?)
          ?.map((option) => TaskOption.fromJson(option as Map<String, dynamic>))
          .toList(),
      blankGroups: (json['blankGroups'] as List<dynamic>?)
          ?.map((group) => BlankGroup.fromJson(group as Map<String, dynamic>))
          .toList(),
      prepSeconds: json['prepSeconds'] as int,
      responseSeconds: json['responseSeconds'] as int,
      prepDeadline: DateTime.parse(json['prepDeadline'] as String),
      responseDeadline: DateTime.parse(json['responseDeadline'] as String),
      serverNow: DateTime.parse(json['serverNow'] as String),
      examEndTime: json['examEndTime'] == null ? null : DateTime.parse(json['examEndTime'] as String),
    );
  }
}

/// Response shape shared by `POST /attempts` (start/resume) and
/// `GET /attempts/{id}/next-task` — `completed:true, task:null` is a
/// normal terminal outcome (the server auto-completed the attempt), not
/// an error. Callers must check [completed] before touching [task]
/// (phase-03 Design Constraints — the ordering bug this guards against is
/// treating "terminal" as "not loaded yet").
class AttemptTaskResponse {
  const AttemptTaskResponse({
    required this.attemptPublicId,
    required this.attemptStatus,
    required this.completed,
    this.task,
    this.encryptionPublicKey,
  });

  final String attemptPublicId;
  final String attemptStatus;
  final bool completed;
  final TaskView? task;

  /// Base64 X.509 SubjectPublicKeyInfo — non-null only when this attempt's
  /// pinned `answerIntegrityLevel == STRICT` (task 20, Phase 1). Its presence
  /// alone is the signal to encrypt submissions; there is no separate
  /// boolean field for the integrity level itself.
  final String? encryptionPublicKey;

  factory AttemptTaskResponse.fromJson(Map<String, dynamic> json) {
    return AttemptTaskResponse(
      attemptPublicId: json['attemptPublicId'] as String,
      attemptStatus: json['attemptStatus'] as String,
      completed: json['completed'] as bool,
      task: json['task'] == null ? null : TaskView.fromJson(json['task'] as Map<String, dynamic>),
      encryptionPublicKey: json['encryptionPublicKey'] as String?,
    );
  }
}
