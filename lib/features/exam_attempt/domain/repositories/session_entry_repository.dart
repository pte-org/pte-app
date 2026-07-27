/// Thrown when a session ID cannot be resolved (empty manual entry, an
/// unparseable deep link) — never signaled by returning an empty string or
/// leaving the returned future unresolved.
class SessionResolutionException implements Exception {
  const SessionResolutionException(this.message);

  final String message;

  @override
  String toString() => 'SessionResolutionException: $message';
}

/// Resolves the `sessionPublicId` a student wants to enter/resume, from
/// whatever raw form the UI collected (`rawInput` — manual text today, a
/// deep-link URI or a picked list item's ID later).
///
/// Member 3's session-discovery mechanism (self-service list vs.
/// host-shared link) is unresolved as of this plan's writing (`plan.md`
/// Risks). This interface is the swap seam: `ExamAttemptBloc` depends only
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
