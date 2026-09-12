/// Stable labels and formatting rules shared by the exam shell.
///
/// Dynamic candidate, task and timer values remain inputs to the shell; this
/// class does not manufacture production metadata for missing API fields.
class ExamChromeConfig {
  const ExamChromeConfig._();

  static const String brandLabel = 'Pearson';
  static const String defaultExamTitle = 'PTE Academic';
  static const String unavailableCandidateId = 'Candidate ID unavailable';
  static const String saveAndExitLabel = 'Save & Exit';
  static const String previousLabel = 'Previous';
  static const String nextLabel = 'Next';
  static const String audioCheckTooltip = 'Audio check';
  static const String submitExamTooltip = 'Submit exam';
  static const String unavailableItemLabel = 'Item --';

  static String itemLabel({required int? orderIndex, required int totalTasks}) {
    final item = orderIndex == null
        ? unavailableItemLabel
        : 'Item ${orderIndex + 1}';
    return '$item of $totalTasks';
  }

  static String formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
