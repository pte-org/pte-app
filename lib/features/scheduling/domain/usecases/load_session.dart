import '../repositories/scheduling_repository.dart';
import '../session_types.dart';

class LoadSession {
  const LoadSession({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<ExamSession> call(String publicId) =>
      _repository.loadSession(publicId);
}
