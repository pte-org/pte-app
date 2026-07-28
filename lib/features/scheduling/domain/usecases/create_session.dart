import '../repositories/scheduling_repository.dart';
import '../session_types.dart';

class CreateSession {
  const CreateSession({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<ExamSession> call(CreateSessionInput input) =>
      _repository.createSession(input);
}
