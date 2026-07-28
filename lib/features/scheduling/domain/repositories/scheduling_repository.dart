import '../session_types.dart';
import '../participant_types.dart';

abstract interface class SchedulingRepository {
  Future<List<ExamSession>> loadSessions();
  Future<ExamSession> loadSession(String publicId);
  Future<ExamSession> createSession(CreateSessionInput input);
  Future<ExamSession> setComposition(
    String publicId,
    SetCompositionInput input,
  );
  Future<ExamSession> openSession(String publicId);
  Future<ExamSession> closeSession(String publicId);
  Future<List<SnapshotTaskOption>> loadSnapshotOptions(String snapshotPublicId);
  Future<EnrollmentResult> enrollStudent(
    String sessionPublicId,
    String studentPublicId,
  );
  Future<ProctorAssignmentResult> assignProctor(
    String sessionPublicId,
    String proctorPublicId,
  );
}
