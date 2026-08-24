import '../blueprint_types.dart';
import '../repositories/authoring_repository.dart';

class LoadBlueprints {
  const LoadBlueprints({required AuthoringRepository repository})
    : _repository = repository;
  final AuthoringRepository _repository;
  Future<List<Blueprint>> call() => _repository.loadBlueprints();
}
