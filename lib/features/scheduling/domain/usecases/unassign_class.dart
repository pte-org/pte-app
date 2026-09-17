import '../repositories/scheduling_repository.dart';

class UnassignClass {
  const UnassignClass({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<void> call(String sessionPublicId, String classPublicId) =>
      _repository.unassignClass(sessionPublicId, classPublicId);
}
