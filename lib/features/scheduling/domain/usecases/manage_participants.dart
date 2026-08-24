import '../participant_types.dart';
import '../repositories/scheduling_repository.dart';

class EnrollStudent {
  const EnrollStudent({required SchedulingRepository repository})
    : _repository = repository;
  final SchedulingRepository _repository;
  Future<EnrollmentResult> call(String sessionId, String studentId) =>
      _repository.enrollStudent(sessionId, studentId);
}

class AssignProctor {
  const AssignProctor({required SchedulingRepository repository})
    : _repository = repository;
  final SchedulingRepository _repository;
  Future<ProctorAssignmentResult> call(String sessionId, String proctorId) =>
      _repository.assignProctor(sessionId, proctorId);
}
