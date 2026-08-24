import '../live_proctor_types.dart';

abstract interface class LiveProctorRepository {
  Future<List<AssignedProctorSession>> loadAssignedSessions();

  Future<List<ViolationEvent>> loadViolations(String sessionPublicId);
}
