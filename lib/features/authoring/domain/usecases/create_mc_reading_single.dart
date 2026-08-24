import '../authoring_types.dart';
import '../repositories/authoring_repository.dart';

class CreateMcReadingSingle {
  const CreateMcReadingSingle({required AuthoringRepository repository})
    : _repository = repository;

  final AuthoringRepository _repository;

  Future<Question> call(CreateMcReadingSingleInput input) {
    return _repository.createMcReadingSingle(input.normalized());
  }
}
