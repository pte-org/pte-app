import '../host_user.dart';

abstract interface class HostUserRepository {
  Future<List<HostUser>> loadUsers();
}
