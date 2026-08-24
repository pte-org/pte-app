import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/live_proctor_repository.dart';
import 'assigned_sessions_event.dart';
import 'assigned_sessions_state.dart';

class AssignedSessionsBloc
    extends Bloc<AssignedSessionsEvent, AssignedSessionsState> {
  AssignedSessionsBloc({required LiveProctorRepository repository})
    : _repository = repository,
      super(const AssignedSessionsInitial()) {
    on<AssignedSessionsRequested>(_onRequested);
  }

  final LiveProctorRepository _repository;

  Future<void> _onRequested(
    AssignedSessionsRequested event,
    Emitter<AssignedSessionsState> emit,
  ) async {
    emit(const AssignedSessionsLoading());
    try {
      final sessions = await _repository.loadAssignedSessions();
      emit(
        sessions.isEmpty
            ? const AssignedSessionsEmpty()
            : AssignedSessionsLoaded(List.unmodifiable(sessions)),
      );
    } catch (error) {
      emit(AssignedSessionsFailure(error));
    }
  }
}
