import '../authoring_types.dart';
import '../repositories/authoring_repository.dart';

class CreateReadAloud {
  const CreateReadAloud({required AuthoringRepository repository})
    : _repository = repository;

  final AuthoringRepository _repository;

  Future<Question> call(CreateReadAloudInput input) {
    return _repository.createReadAloud(input.normalized());
  }
}
