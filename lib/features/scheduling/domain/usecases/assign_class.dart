import '../repositories/scheduling_repository.dart';
import '../session_types.dart';

class AssignClass {
  const AssignClass({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<AssignedClass> call(String sessionPublicId, String classPublicId) =>
      _repository.assignClass(sessionPublicId, classPublicId);
}
