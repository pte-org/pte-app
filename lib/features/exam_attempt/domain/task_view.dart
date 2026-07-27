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
    return TaskOption(text: json['text'] as String, orderIndex: json['orderIndex'] as String);
  }
}

/// The full task shape returned by both `startOrResumeAttempt` and
/// `fetchNextTask` (phase-03 Steps). This phase only carries every field
/// through untouched — Phase 4/5/6 are what consume `prepDeadline`/
/// `responseDeadline`/`options` etc.
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
    required this.prepSeconds,
    required this.responseSeconds,
    required this.prepDeadline,
    required this.responseDeadline,
    required this.serverNow,
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
  final int prepSeconds;
  final int responseSeconds;
  final DateTime prepDeadline;
  final DateTime responseDeadline;
  final DateTime serverNow;

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
      prepSeconds: json['prepSeconds'] as int,
      responseSeconds: json['responseSeconds'] as int,
      prepDeadline: DateTime.parse(json['prepDeadline'] as String),
      responseDeadline: DateTime.parse(json['responseDeadline'] as String),
      serverNow: DateTime.parse(json['serverNow'] as String),
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
  });

  final String attemptPublicId;
  final String attemptStatus;
  final bool completed;
  final TaskView? task;

  factory AttemptTaskResponse.fromJson(Map<String, dynamic> json) {
    return AttemptTaskResponse(
      attemptPublicId: json['attemptPublicId'] as String,
      attemptStatus: json['attemptStatus'] as String,
      completed: json['completed'] as bool,
      task: json['task'] == null ? null : TaskView.fromJson(json['task'] as Map<String, dynamic>),
    );
  }
}
