/// The host-facing, read-only session row used to choose a preview.
class HostExamSummary {
  const HostExamSummary({
    required this.publicId,
    required this.sessionCode,
    required this.name,
    required this.status,
    required this.examVersionPublicId,
  });

  final String publicId;
  final String? sessionCode;
  final String name;
  final String status;
  final String? examVersionPublicId;

  bool get hasSnapshot => examVersionPublicId != null;

  bool get canPreview =>
      hasSnapshot &&
      const {
        'READY',
        'SCHEDULED',
        'OPEN',
        'CLOSED',
        'CANCELLED',
      }.contains(status);
}
