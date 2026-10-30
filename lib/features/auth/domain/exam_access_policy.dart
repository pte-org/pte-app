import 'jwt_claims.dart';

/// Hosts, proctors, examiners and platform staff work in pte-web; this client
/// only delivers exams. UI gate only — the backend still refuses any exam
/// call from an account that is not an enrolled student.
abstract final class ExamAccessPolicy {
  static const String _studentRole = 'STUDENT';
  static const String _hostAdminRole = 'HOST_ADMIN';

  static bool canTakeExam(JwtClaims claims) =>
      claims.roles.contains(_studentRole);

  /// Host preview is a separate authenticated context. A user carrying both
  /// roles enters this context first; the app never silently turns a host
  /// preview into a student attempt.
  static bool canPreviewExam(JwtClaims claims) =>
      claims.roles.contains(_hostAdminRole);
}
