/// Copy owned by the authenticated host exam preview feature.
abstract final class ExamPreviewStrings {
  static const String sessionIdRequired = 'Session id cannot be empty';
  static const String sessionNotFound =
      'Exam code was not found in your organization.';
  static const String sessionNotReady =
      'This exam has not generated its questions yet.';
  static const String hostName = 'Host';
  static const String completed = 'Completed';
  static const String playing = 'Playing';
  static const String paused = 'Paused';
  static const String stopped = 'Stopped';
  static const String audioLoading = 'Loading audio';
  static const String audioFailed = 'Audio unavailable';
  static const String audioReady = 'Ready';
  static const String emptyResponse = 'Preview response is empty';
  static const String emptyTasks = 'Exam preview has no tasks';
  static const String itemsRequired = 'Preview response has no items array';
  static const String stableIdentifierRequired =
      'Missing stable preview identifier';
  static const String untitledExam = 'Untitled exam';
  static const String previewTitle = 'Exam preview';
  static const String listTitle = 'Host exam preview';
  static const String logout = 'Log out';
  static const String listErrorTitle = 'Unable to load exams';
  static const String listErrorMessage =
      'The host exam list could not be loaded. Try again.';
  static const String retry = 'Retry';
  static const String emptyListTitle = 'No exams yet';
  static const String emptyListMessage =
      'Create an exam in the host web portal to preview it here.';
  static const String snapshotAvailable = 'Snapshot available';
  static const String snapshotUnavailable =
      'Preview unavailable until a snapshot is generated';
  static const String preview = 'Preview';
  static const String previous = 'Previous';
  static const String finish = 'Finish preview';
  static const String next = 'Next';
  static const String previewErrorTitle = 'Exam unavailable';
  static const String previewErrorMessage =
      'The exam could not be opened. Check the exam code and try again.';
  static const String taskTitle = 'Task';
  static const String defaultInstruction =
      'Follow the instructions for this task.';
  static const String unsupportedTitle = 'Task cannot be previewed';
  static const String previewOnly = 'Preview only · no answer submission';
  static const String noStimulusTitle = 'No additional stimulus';
  static const String noStimulusMessage =
      'This task starts with the response instruction.';
  static const String audioLabel = 'Task audio';
  static const String imageErrorTitle = 'Image unavailable';
  static const String imageErrorMessage =
      'The signed image could not be loaded for this preview.';
  static const String startRecording = 'Start local recording';
  static const String stopRecording = 'Stop & discard';
  static const String recordingTitle = 'Host preview recording';
  static const String recordingMessage =
      'Any recording is temporary and is never uploaded or scored.';
  static const String responseLabel = 'Local preview response';
  static const String draftTitle = 'Response draft';
  static const String draftMessage =
      'Typing is local to this preview and is never submitted.';
  static const String responseErrorTitle = 'Response unavailable';
  static const String responseErrorMessage =
      'This task has no compatible local response control.';
  static String missingField(String field) =>
      'Missing $field in host exam response';
  static String unsupportedTask(String identifier) =>
      'This task is not supported by the current app renderer ($identifier).';
  static String examHeading(String name) => '$name · Host preview';
  static String remainingTime(int seconds) => 'Time ${seconds}s';
  static String sessionSummary(String code, String status) => '$code · $status';
  static String taskProgress(int current, int total) => '$current / $total';
  static String taskTiming(int preparation, int response) =>
      'Prep: ${preparation}s | Response: ${response}s';
  static String wordBounds(int? min, int? max) =>
      '${min ?? 0}–${max ?? '∞'} words';
  static String optionLabel(int index) => 'Option $index';
  static String blankLabel(int index) => 'Blank $index';
  static String wordCount(String text) {
    final trimmed = text.trim();
    final count = trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
    return '$count words';
  }
}
