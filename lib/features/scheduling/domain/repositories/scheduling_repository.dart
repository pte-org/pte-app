import '../session_types.dart';
import '../participant_types.dart';

abstract interface class SchedulingRepository {
  Future<List<ExamSession>> loadSessions();
  Future<ExamSession> loadSession(String publicId);
  Future<ExamSession> createSession(CreateSessionInput input);
  Future<ExamSession> openSession(String publicId);
  Future<ExamSession> closeSession(String publicId);
  Future<List<AssignedClass>> loadAssignedClasses(String sessionPublicId);
  Future<AssignedClass> assignClass(String sessionPublicId, String classPublicId);
  Future<void> unassignClass(String sessionPublicId, String classPublicId);
  Future<EnrollmentResult> enrollStudent(
    String sessionPublicId,
    String studentPublicId,
  );
  Future<ProctorAssignmentResult> assignProctor(
    String sessionPublicId,
    String proctorPublicId,
  );
}
