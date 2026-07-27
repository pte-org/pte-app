import '../report_response.dart';

/// Read-only — no dependency on Phase 2's outbox/sync machinery; reporting
/// is a pure fetch-and-render concern (phase-08 Design Constraints).
///
/// [fetchReport] returns `null` for a 404 rather than throwing — the
/// backend cannot distinguish "not yet published" from "not found/not
/// owned," and treating both as a bare `null` return means `ReportBloc`
/// never needs its own ad hoc "is this 404 actually fine" branching
/// duplicated from this repository (phase-08 Design Constraints).
abstract class ReportRepository {
  Future<ReportResponse?> fetchReport(String attemptPublicId);
}
