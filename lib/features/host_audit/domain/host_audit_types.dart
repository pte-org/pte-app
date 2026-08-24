class NotificationAudit {
  const NotificationAudit({
    required this.publicId,
    required this.recipientEmail,
    required this.notificationType,
    required this.subject,
    required this.status,
    required this.sentAt,
  });

  final String publicId;
  final String recipientEmail;
  final String notificationType;
  final String subject;
  final String status;
  final DateTime? sentAt;
}

class ViolationAuditEvent {
  const ViolationAuditEvent({
    required this.publicId,
    required this.attemptPublicId,
    required this.violationType,
    required this.detail,
    required this.sequenceNo,
    required this.hash,
    required this.detectedAt,
  });

  final String publicId;
  final String attemptPublicId;
  final String violationType;
  final String detail;
  final int sequenceNo;
  final String hash;
  final DateTime detectedAt;
}
