import '../blueprint_types.dart';
import '../repositories/authoring_repository.dart';

class CreateBlueprint {
  const CreateBlueprint({required AuthoringRepository repository})
    : _repository = repository;
  final AuthoringRepository _repository;
  Future<Blueprint> call(CreateBlueprintInput input) =>
      _repository.createBlueprint(input.normalized());
}
