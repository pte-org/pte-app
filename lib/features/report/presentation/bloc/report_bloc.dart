import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/report/domain/repositories/report_repository.dart';
import 'package:pte_app/features/report/presentation/bloc/report_event.dart';
import 'package:pte_app/features/report/presentation/bloc/report_state.dart';

/// Read-only — no dependency on Phase 2's `AnswerOutboxDao`/`SyncEngine`,
/// structurally simpler than every prior phase's `Bloc` (phase-08 Design
/// Constraints).
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc({required ReportRepository repository}) : _repository = repository, super(const ReportLoading()) {
    on<ReportRequested>(_onFetch);
    on<ReportRefreshRequested>(_onFetch);
  }

  final ReportRepository _repository;

  Future<void> _onFetch(ReportEvent event, Emitter<ReportState> emit) async {
    final attemptPublicId = switch (event) {
      ReportRequested() => event.attemptPublicId,
      ReportRefreshRequested() => event.attemptPublicId,
    };
    emit(const ReportLoading());
    try {
      final report = await _repository.fetchReport(attemptPublicId);
      // `null` is the repository's dedicated 404 signal, not "not loaded
      // yet" — this Bloc never re-derives 404-ness from an exception type
      // itself (phase-08 Design Constraints).
      emit(report == null ? const ReportNotPublished() : ReportReady(report));
    } catch (e) {
      emit(ReportError(e is Exception ? e : UnknownApiException(e.toString())));
    }
  }
}
