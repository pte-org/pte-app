import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_sessions.dart';
import 'session_list_event.dart';
import 'session_list_state.dart';

class SessionListBloc extends Bloc<SessionListEvent, SessionListState> {
  SessionListBloc({required LoadSessions loadSessions})
    : _loadSessions = loadSessions,
      super(const SessionListInitial()) {
    on<SessionListRequested>(_onRequested);
  }

  final LoadSessions _loadSessions;

  Future<void> _onRequested(
    SessionListRequested event,
    Emitter<SessionListState> emit,
  ) async {
    emit(const SessionListLoading());
    try {
      final sessions = await _loadSessions();
      emit(
        sessions.isEmpty
            ? const SessionListEmpty()
            : SessionListLoaded(sessions),
      );
    } catch (error) {
      emit(SessionListFailure(error));
    }
  }
}
