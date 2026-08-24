import '../blueprint_types.dart';
import '../repositories/authoring_repository.dart';

class PublishBlueprint {
  const PublishBlueprint({required AuthoringRepository repository})
    : _repository = repository;
  final AuthoringRepository _repository;
  Future<ExamSnapshot> call(String publicId) =>
      _repository.publishBlueprint(publicId);
}
