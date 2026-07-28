import '../../domain/report_response.dart';

/// Four separate immutable classes, no boolean-flag shape (phase-08 Design
/// Constraints).
sealed class ReportState {
  const ReportState();
}

final class ReportLoading extends ReportState {
  const ReportLoading();
}

/// The 404 case — indistinguishably "not yet published" or "not owned"
/// (the latter isn't a case a student can legitimately hit through this
/// flow). Never routed to [ReportError] (phase-08 Design Constraints).
final class ReportNotPublished extends ReportState {
  const ReportNotPublished();
}

final class ReportReady extends ReportState {
  const ReportReady(this.report);

  final ReportResponse report;
}

/// Reserved for genuine failures (network error, 5xx, malformed response)
/// — a 404 never reaches this state (phase-08 Design Constraints).
final class ReportError extends ReportState {
  const ReportError(this.error);

  final Exception error;
}
