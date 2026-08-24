import '../blueprint_types.dart';
import '../repositories/authoring_repository.dart';

class LoadBlueprint {
  const LoadBlueprint({required AuthoringRepository repository})
    : _repository = repository;
  final AuthoringRepository _repository;
  Future<Blueprint> call(String publicId) =>
      _repository.loadBlueprint(publicId);
}
