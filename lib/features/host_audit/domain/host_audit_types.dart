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
    required this.detectedAt,
    this.source = 'PROCTOR',
    this.severity = 'WARNING',
    this.clientEventId,
    this.studentPublicId,
    this.sequenceNo,
    this.hash,
  });

  final String publicId;
  final String attemptPublicId;
  final String violationType;
  final String? detail;
  final DateTime detectedAt;
  final String source;
  final String severity;
  final String? clientEventId;
  final String? studentPublicId;
  final int? sequenceNo;
  final String? hash;
}

class ViolationAuditPageData {
  const ViolationAuditPageData({required this.items, this.nextCursor});

  final List<ViolationAuditEvent> items;
  final String? nextCursor;
}
