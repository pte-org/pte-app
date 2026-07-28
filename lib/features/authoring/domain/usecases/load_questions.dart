import '../authoring_types.dart';
import '../repositories/authoring_repository.dart';

class LoadQuestions {
  const LoadQuestions({required AuthoringRepository repository})
    : _repository = repository;

  final AuthoringRepository _repository;

  Future<List<Question>> call() => _repository.loadQuestions();
}
