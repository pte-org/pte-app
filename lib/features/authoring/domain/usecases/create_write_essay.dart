import '../authoring_types.dart';
import '../repositories/authoring_repository.dart';

class CreateWriteEssay {
  const CreateWriteEssay({required AuthoringRepository repository})
    : _repository = repository;

  final AuthoringRepository _repository;

  Future<Question> call(CreateWriteEssayInput input) {
    return _repository.createWriteEssay(input.normalized());
  }
}
