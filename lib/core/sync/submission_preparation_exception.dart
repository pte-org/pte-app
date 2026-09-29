/// A terminal submit cannot safely proceed while a locally captured answer or
/// recording is still waiting for the server-side answer pipeline.
///
/// This is intentionally owned by the sync layer so [SyncEngine] and
/// [MediaUploadCoordinator] can report the same preparation contract without
/// depending on the exam feature's BLoC.
enum SubmissionPreparationKind { answers, media }

final class SubmissionPreparationException implements Exception {
  const SubmissionPreparationException({
    required this.kind,
    required this.pendingCount,
  });

  final SubmissionPreparationKind kind;
  final int pendingCount;

  @override
  String toString() =>
      'SubmissionPreparationException(kind: $kind, pendingCount: $pendingCount)';
}
