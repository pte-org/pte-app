/// Repository contract for the Speaking exam section.
///
/// - `uploadRecording` uploads raw audio bytes to Cloudinary via the BE and
///   returns the CDN URL of the stored file.
/// - `submitAnswer` persists the audio URL as an `AttemptAnswer` on the BE.
///
/// Both operations are no-ops when [attemptId] or [questionId] is null
/// (i.e. when the page is running in mock/preview mode).
abstract class SpeakingRepository {
  Future<String> uploadRecording({
    required int attemptId,
    required int questionId,
    required List<int> audioBytes,
    required String mimeType,
    String filename,
  });

  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    required String audioUrl,
  });
}
