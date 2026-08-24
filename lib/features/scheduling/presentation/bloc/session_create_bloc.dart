import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/session_types.dart';
import '../../domain/usecases/create_session.dart';
import 'session_create_event.dart';
import 'session_create_state.dart';

typedef Clock = DateTime Function();

class SessionCreateBloc extends Bloc<SessionCreateEvent, SessionCreateState> {
  SessionCreateBloc({required CreateSession createSession, Clock? clock})
    : _createSession = createSession,
      _clock = clock ?? DateTime.now,
      super(const SessionCreateInitial()) {
    on<SessionCreateSubmitted>(_onSubmitted);
  }

  final CreateSession _createSession;
  final Clock _clock;
  bool _submitting = false;

  Future<void> _onSubmitted(
    SessionCreateSubmitted event,
    Emitter<SessionCreateState> emit,
  ) async {
    if (_submitting) return;
    late final CreateSessionInput input;
    try {
      input = event.input.normalized(now: _clock());
    } on SchedulingValidationException catch (error) {
      emit(SessionCreateInvalid(error.message));
      return;
    }
    _submitting = true;
    emit(const SessionCreateSubmitting());
    try {
      emit(SessionCreateSuccess(await _createSession(input)));
    } catch (error) {
      emit(SessionCreateFailure(error));
    } finally {
      _submitting = false;
    }
  }
}
