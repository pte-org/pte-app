import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_participants.dart';
import 'participant_command_event.dart';
import 'participant_command_state.dart';

class EnrollmentBloc
    extends Bloc<ParticipantCommandEvent, ParticipantCommandState> {
  EnrollmentBloc({required EnrollStudent enrollStudent})
    : _enrollStudent = enrollStudent,
      super(const ParticipantIdle()) {
    on<EnrollmentSubmitted>(_onSubmit);
  }
  final EnrollStudent _enrollStudent;
  bool _submitting = false;

  Future<void> _onSubmit(
    EnrollmentSubmitted event,
    Emitter<ParticipantCommandState> emit,
  ) async {
    if (_submitting) return;
    _submitting = true;
    emit(const ParticipantSubmitting());
    try {
      emit(
        ParticipantSuccess(
          await _enrollStudent(event.sessionPublicId, event.studentPublicId),
        ),
      );
    } catch (error) {
      emit(ParticipantFailure(error));
    } finally {
      _submitting = false;
    }
  }
}

class ProctorAssignmentBloc
    extends Bloc<ParticipantCommandEvent, ParticipantCommandState> {
  ProctorAssignmentBloc({required AssignProctor assignProctor})
    : _assignProctor = assignProctor,
      super(const ParticipantIdle()) {
    on<ProctorAssignmentSubmitted>(_onSubmit);
  }
  final AssignProctor _assignProctor;
  bool _submitting = false;

  Future<void> _onSubmit(
    ProctorAssignmentSubmitted event,
    Emitter<ParticipantCommandState> emit,
  ) async {
    if (_submitting) return;
    _submitting = true;
    emit(const ParticipantSubmitting());
    try {
      emit(
        ParticipantSuccess(
          await _assignProctor(event.sessionPublicId, event.proctorPublicId),
        ),
      );
    } catch (error) {
      emit(ParticipantFailure(error));
    } finally {
      _submitting = false;
    }
  }
}
