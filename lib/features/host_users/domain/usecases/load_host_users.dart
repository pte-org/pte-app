import '../host_user.dart';
import '../repositories/host_user_repository.dart';

class LoadHostUsers {
  const LoadHostUsers({required HostUserRepository repository})
    : _repository = repository;

  final HostUserRepository _repository;
  Future<List<HostUser>> call() => _repository.loadUsers();
}
