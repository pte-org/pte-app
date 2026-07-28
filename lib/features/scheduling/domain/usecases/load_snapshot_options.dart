import '../repositories/scheduling_repository.dart';
import '../session_types.dart';

class LoadSnapshotOptions {
  const LoadSnapshotOptions({required SchedulingRepository repository})
    : _repository = repository;

  final SchedulingRepository _repository;
  Future<List<SnapshotTaskOption>> call(String snapshotPublicId) =>
      _repository.loadSnapshotOptions(snapshotPublicId);
}
