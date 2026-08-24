import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_host_audit.dart';
import 'violation_audit_event.dart';
import 'violation_audit_state.dart';

class ViolationAuditBloc
    extends Bloc<ViolationAuditBlocEvent, ViolationAuditState> {
  ViolationAuditBloc({required LoadViolations loadViolations})
    : _loadViolations = loadViolations,
      super(const ViolationAuditInitial()) {
    on<ViolationAuditRequested>(_onLoad);
  }

  final LoadViolations _loadViolations;

  Future<void> _onLoad(
    ViolationAuditRequested event,
    Emitter<ViolationAuditState> emit,
  ) async {
    emit(const ViolationAuditLoading());
    try {
      final items = await _loadViolations(event.sessionPublicId);
      emit(
        items.isEmpty
            ? const ViolationAuditEmpty()
            : ViolationAuditLoaded(items),
      );
    } catch (error) {
      emit(ViolationAuditFailure(error));
    }
  }
}
