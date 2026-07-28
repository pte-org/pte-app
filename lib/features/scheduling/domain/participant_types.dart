class EnrollmentResult {
  const EnrollmentResult({
    required this.publicId,
    required this.sessionPublicId,
    required this.studentPublicId,
  });
  final String publicId;
  final String sessionPublicId;
  final String studentPublicId;
}

class ProctorAssignmentResult {
  const ProctorAssignmentResult({
    required this.publicId,
    required this.sessionPublicId,
    required this.proctorPublicId,
  });
  final String publicId;
  final String sessionPublicId;
  final String proctorPublicId;
}
