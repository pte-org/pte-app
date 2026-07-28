import '../repositories/scheduling_repository.dart';
import '../session_types.dart';

class UpdateSessionComposition {
  const UpdateSessionComposition({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<ExamSession> call(String publicId, SetCompositionInput input) =>
      _repository.setComposition(publicId, input);
}
