import 'jwt_claims.dart';

/// Hosts, proctors, examiners and platform staff work in pte-web; this client
/// only delivers exams. UI gate only — the backend still refuses any exam
/// call from an account that is not an enrolled student.
abstract final class ExamAccessPolicy {
  static const String _studentRole = 'STUDENT';

  static bool canTakeExam(JwtClaims claims) =>
      claims.roles.contains(_studentRole);
}
