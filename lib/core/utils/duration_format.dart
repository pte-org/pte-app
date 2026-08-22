/// Formats [duration] as `mm:ss` (e.g. `00:34`), clock-style — minutes are
/// not clamped to 59, so a duration over an hour renders as e.g. `75:03`
/// rather than wrapping. Shared by every countdown/elapsed-time display
/// (`ExamAppBar`'s per-task countdown, the read-aloud recording indicator)
/// so they can never drift out of formatting sync with each other.
String formatMmSs(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
}

/// Formats [duration] as `hh:mm:ss` (e.g. `00:39:16`) — used where a
/// duration can exceed an hour, unlike [formatMmSs]'s callers. Hours are
/// not clamped to 23, matching [formatMmSs]'s own no-wrap convention.
String formatHhMmSs(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
}
