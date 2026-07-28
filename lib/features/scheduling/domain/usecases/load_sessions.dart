import '../repositories/scheduling_repository.dart';
import '../session_types.dart';

class LoadSessions {
  const LoadSessions({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<List<ExamSession>> call() => _repository.loadSessions();
}
