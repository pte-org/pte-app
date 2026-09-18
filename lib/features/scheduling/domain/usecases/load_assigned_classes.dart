import '../repositories/scheduling_repository.dart';
import '../session_types.dart';

class LoadAssignedClasses {
  const LoadAssignedClasses({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<List<AssignedClass>> call(String sessionPublicId) =>
      _repository.loadAssignedClasses(sessionPublicId);
}
