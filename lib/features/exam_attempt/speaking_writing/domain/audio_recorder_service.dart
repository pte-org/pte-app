/// Thin seam over `package:record`'s recorder so `ReadAloudCubit` is
/// testable without touching real device hardware.
abstract class AudioRecorderService {
  /// Starts recording, writing to [filePath] as it captures — never held
  /// only in memory (phase-06 Design Constraints).
  Future<void> start(String filePath);

  /// Stops recording and returns the final file path, or `null` if
  /// nothing was recorded.
  Future<String?> stop();

  Future<bool> isRecording();
}
