import 'package:pte_app/core/constants/task_type_meta.dart';

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
/// `fetchNextTask`. [prepSeconds]/[responseSeconds] are the only timing
/// signal (client-side-exam-timer Phase 3) — [TimerService.seedFromTask]
/// consumes them directly, with no absolute deadline timestamp needed.
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
    this.examEndTime,
    this.preListenSeconds,
    this.preRecordSeconds,
    this.imageUrl,
    this.taskTypeCode,
    this.runtime,
    this.taskTypeDisplayName,
  });

  final String pinnedItemPublicId;
  final int orderIndex;
  final int totalTasks;
  final String section;
  final String taskType;

  /// Additive canonical code. [taskType] remains populated for legacy wire
  /// compatibility; [canonicalTaskType] is the alias-normalized identity
  /// used by the registry and presentation adapters.
  final String? taskTypeCode;

  /// Immutable server runtime metadata for new snapshots. Null means this is
  /// an older response and the app must use the alias-aware legacy registry.
  final TaskRuntimeProfile? runtime;
  final String? taskTypeDisplayName;

  String get canonicalTaskType =>
      TaskTypeCodes.canonicalize(taskTypeCode ?? taskType) ?? taskType;
  final String title;
  final String? promptText;
  final String? audioPromptRef;

  /// The raw MediaObject public ID — never a directly-loadable URL. Kept
  /// for parity with the backend DTO (`imagePromptRef` stays present there
  /// too, unchanged), but no screen should read this to display an image;
  /// use [imageUrl] instead, which the server resolves to a real presigned
  /// URL at pin time (plans/phat-describe-image-e2e).
  final String? imagePromptRef;
  final int? minWordCount;
  final int? maxWordCount;
  final List<TaskOption>? options;
  final List<BlankGroup>? blankGroups;

  /// The client-side-exam-timer refactor's ONLY timing signal per task
  /// (FR-01) — [TimerService.seedFromTask] computes its own local wall-clock
  /// deadlines directly from these two ints, anchored to `DateTime.now()` at
  /// seed time. No more `prepDeadline`/`responseDeadline`/`serverNow` —
  /// for a section-scoped task (READING), [responseSeconds] already reflects
  /// the live remaining shared-section budget, not just this task's own
  /// slice (computed server-side; see `AttemptMapper.toTaskResponse`'s doc
  /// comment in `pte-api`).
  final int prepSeconds;
  final int responseSeconds;

  /// Whole-attempt deadline (`ExamAttempt.startedAt` + every pinned item's
  /// `prepSeconds + responseSeconds`) — distinct from [prepSeconds]/
  /// [responseSeconds], which govern only the current task/section. Still an
  /// absolute timestamp (unaffected by the client-side-exam-timer refactor —
  /// out of its scope). Null only for an attempt created before the backend
  /// started populating this field.
  final DateTime? examEndTime;

  /// Server-owned sub-stage lengths for the 5 audio-prompt Speaking task
  /// types (Repeat Sentence, Retell Lecture, Answer Short Question,
  /// Summarize Group Discussion, Respond to a Situation) — non-null ONLY
  /// for those 5, `null` for every other task type (~20 others), which
  /// never read either field. Deliberately nullable, not a hard non-null
  /// cast the way [prepSeconds]/[responseSeconds] are parsed — those two
  /// really are populated for every task type; these two are not
  /// (plans/phat-speaking-dynamic-prep-timing).
  final int? preListenSeconds;
  final int? preRecordSeconds;

  /// Resolved, directly-fetchable presigned URL for [imagePromptRef] — null
  /// unless the server resolved one (mandatory for DESCRIBE_IMAGE, absent
  /// for every other task type today). Unlike Speaking's audio prompts
  /// (played on demand via a separate replay-limited endpoint), a static
  /// image has no such concern, so it's embedded directly here
  /// (plans/phat-describe-image-e2e).
  final String? imageUrl;

  factory TaskView.fromJson(Map<String, dynamic> json) {
    return TaskView(
      pinnedItemPublicId: json['pinnedItemPublicId'] as String,
      orderIndex: json['orderIndex'] as int,
      totalTasks: json['totalTasks'] as int,
      section: json['section'] as String,
      taskType: json['taskType'] as String,
      taskTypeCode: json['taskTypeCode'] as String?,
      runtime: _readRuntime(json['runtime']),
      taskTypeDisplayName: json['taskTypeDisplayName'] as String?,
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
      examEndTime: json['examEndTime'] == null
          ? null
          : DateTime.parse(json['examEndTime'] as String),
      preListenSeconds: json['preListenSeconds'] as int?,
      preRecordSeconds: json['preRecordSeconds'] as int?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  static TaskRuntimeProfile? _readRuntime(Object? rawRuntime) {
    if (rawRuntime == null) return null;
    if (rawRuntime is Map) {
      return TaskRuntimeProfile.fromJson(Map<String, dynamic>.from(rawRuntime));
    }
    // A present but malformed runtime object is deliberately represented as
    // an invalid profile so the dispatcher fails closed instead of falling
    // back to a mutable/legacy task-type guess.
    return const TaskRuntimeProfile();
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
    this.lockdownMode,
    this.attemptNumber = 1,
    this.remainingRetries = 0,
    this.canRetry = false,
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

  /// Phase 1's `scheduling` server pins `ExamPolicy.lockdownMode` to the
  /// attempt snapshot (`PinnedExamSnapshot.lockdownMode`) and the
  /// `exam-delivery` mapper projects it back out here. Wire values
  /// match `pte-api`'s `LockdownMode` enum uppercase
  /// (`NONE`/`STANDARD`/`STRICT`), and `null` is tolerated for older
  /// deployments that predate Phase 1 — [ExamAttemptBloc] treats
  /// `null` as `none` to avoid regressing legacy backends
  /// (phase-04 Design Constraints).
  final String? lockdownMode;

  /// Server-assigned sequence and quota metadata; retry authorization never
  /// relies on a client-side counter.
  final int attemptNumber;
  final int remainingRetries;
  final bool canRetry;

  factory AttemptTaskResponse.fromJson(Map<String, dynamic> json) {
    return AttemptTaskResponse(
      attemptPublicId: json['attemptPublicId'] as String,
      attemptStatus: json['attemptStatus'] as String,
      completed: json['completed'] as bool,
      task: json['task'] == null
          ? null
          : TaskView.fromJson(json['task'] as Map<String, dynamic>),
      encryptionPublicKey: json['encryptionPublicKey'] as String?,
      lockdownMode: json['lockdownMode'] as String?,
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      remainingRetries: json['remainingRetries'] as int? ?? 0,
      canRetry: json['canRetry'] as bool? ?? false,
    );
  }
}
