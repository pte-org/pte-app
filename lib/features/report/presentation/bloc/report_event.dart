sealed class ReportEvent {
  const ReportEvent();
}

/// Initial fetch — dispatched once when the report screen is first shown.
final class ReportRequested extends ReportEvent {
  const ReportRequested(this.attemptPublicId);

  final String attemptPublicId;
}

/// Manual re-fetch (pull-to-refresh / a refresh button) — never an
/// automatic timer-based poll, since a 404 here is an expected steady
/// state, not a transient failure worth retrying on its own (phase-08
/// Design Constraints).
final class ReportRefreshRequested extends ReportEvent {
  const ReportRefreshRequested(this.attemptPublicId);

  final String attemptPublicId;
}
