import '../repositories/scheduling_repository.dart';
import '../session_types.dart';

class OpenSession {
  const OpenSession({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<ExamSession> call(String publicId) =>
      _repository.openSession(publicId);
}

class CloseSession {
  const CloseSession({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<ExamSession> call(String publicId) =>
      _repository.closeSession(publicId);
}
