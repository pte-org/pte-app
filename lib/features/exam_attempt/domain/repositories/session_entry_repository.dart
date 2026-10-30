/// Thrown when the student's input cannot be resolved to a session (empty
/// entry, an exam code the student can't use) — never signaled by
/// returning an empty string or leaving the returned future unresolved.
/// Transport failures (network, rate limit, auth) stay [ApiException]s.
class SessionResolutionException implements Exception {
  const SessionResolutionException(this.message);

  final String message;

  @override
  String toString() => 'SessionResolutionException: $message';
}

/// Resolves the `sessionPublicId` a student wants to enter/resume, from
/// whatever raw form the UI collected (`rawInput` — the exam code or a
/// pasted session UUID typed at login today, a deep-link URI later).
///
/// This interface is the swap seam: `ExamAttemptBloc` depends only
/// on this method, never on how a concrete implementation interprets
/// `rawInput`. A drop-in replacement must implement only
/// `resolveSessionPublicId(rawInput)` and the same
/// [SessionResolutionException] contract on invalid/empty input — no
/// other change is permitted to leak into
/// `ExamAttemptBloc`/`ExamAttemptRepository` (phase-03 Design Constraints
/// — this is the explicit acceptance test for whether the interface was
/// cut at the right seam).
abstract class SessionEntryRepository {
  Future<String> resolveSessionPublicId(String rawInput);
}
