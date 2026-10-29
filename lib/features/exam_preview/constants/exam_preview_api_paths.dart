abstract final class ExamPreviewApiPaths {
  static const String sessions = '/api/v1/sessions';
  static String snapshot(String sessionId) =>
      '$sessions/${Uri.encodeComponent(sessionId)}/exam-preview';
}
