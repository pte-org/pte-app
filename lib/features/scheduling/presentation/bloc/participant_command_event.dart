sealed class ParticipantCommandEvent {
  const ParticipantCommandEvent();
}

final class EnrollmentSubmitted extends ParticipantCommandEvent {
  const EnrollmentSubmitted(this.sessionPublicId, this.studentPublicId);
  final String sessionPublicId;
  final String studentPublicId;
}

final class ProctorAssignmentSubmitted extends ParticipantCommandEvent {
  const ProctorAssignmentSubmitted(this.sessionPublicId, this.proctorPublicId);
  final String sessionPublicId;
  final String proctorPublicId;
}
