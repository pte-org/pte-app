/// Formats [duration] as `mm:ss` (e.g. `00:34`), clock-style — minutes are
/// not clamped to 59, so a duration over an hour renders as e.g. `75:03`
/// rather than wrapping. Shared by every countdown/elapsed-time display
/// (`ExamAppBar`, the read-aloud recording indicator) so they can never
/// drift out of formatting sync with each other.
String formatMmSs(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
}
