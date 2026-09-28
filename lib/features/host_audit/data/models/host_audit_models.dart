import '../../domain/host_audit_types.dart';

class NotificationAuditModel {
  const NotificationAuditModel({
    required this.publicId,
    required this.recipientEmail,
    required this.notificationType,
    required this.subject,
    required this.status,
    required this.sentAt,
  });

  factory NotificationAuditModel.fromJson(Map<String, dynamic> json) {
    return NotificationAuditModel(
      publicId: json['publicId'] as String,
      recipientEmail: json['recipientEmail'] as String,
      notificationType: json['notificationType'] as String,
      subject: json['subject'] as String,
      status: json['status'] as String,
      sentAt: _nullableTimestamp(json['sentAt']),
    );
  }

  final String publicId;
  final String recipientEmail;
  final String notificationType;
  final String subject;
  final String status;
  final DateTime? sentAt;

  NotificationAudit toEntity() => NotificationAudit(
    publicId: publicId,
    recipientEmail: recipientEmail,
    notificationType: notificationType,
    subject: subject,
    status: status,
    sentAt: sentAt,
  );
}

class ViolationAuditModel {
  const ViolationAuditModel({
    required this.publicId,
    required this.attemptPublicId,
    required this.violationType,
    required this.detail,
    required this.detectedAt,
    required this.source,
    required this.severity,
    this.clientEventId,
    this.studentPublicId,
    this.sequenceNo,
    this.hash,
  });

  factory ViolationAuditModel.fromJson(Map<String, dynamic> json) {
    return ViolationAuditModel(
      publicId: json['publicId'] as String,
      attemptPublicId: json['attemptPublicId'] as String,
      violationType: json['violationType'] as String,
      detail: json['detail'] as String?,
      detectedAt: _requiredTimestamp(json['detectedAt']),
      source: json['source'] as String? ?? 'PROCTOR',
      severity: json['severity'] as String? ?? 'WARNING',
      clientEventId: json['clientEventId'] as String?,
      studentPublicId: json['studentPublicId'] as String?,
      sequenceNo: json['sequenceNo'] as int?,
      hash: json['hash'] as String?,
    );
  }

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

  ViolationAuditEvent toEntity() => ViolationAuditEvent(
    publicId: publicId,
    attemptPublicId: attemptPublicId,
    violationType: violationType,
    detail: detail,
    detectedAt: detectedAt,
    source: source,
    severity: severity,
    clientEventId: clientEventId,
    studentPublicId: studentPublicId,
    sequenceNo: sequenceNo,
    hash: hash,
  );
}

class ViolationAuditPageModel {
  const ViolationAuditPageModel({required this.items, this.nextCursor});

  factory ViolationAuditPageModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    final entries = rawEntries is List<dynamic>
        ? rawEntries
        : const <dynamic>[];
    return ViolationAuditPageModel(
      items: entries
          .map(
            (value) => ViolationAuditModel.fromJson(
              value as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList(growable: false),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<ViolationAuditEvent> items;
  final String? nextCursor;

  ViolationAuditPageData toEntity() =>
      ViolationAuditPageData(items: items, nextCursor: nextCursor);
}

DateTime? _nullableTimestamp(Object? value) {
  if (value == null) return null;
  return _requiredTimestamp(value);
}

DateTime _requiredTimestamp(Object? value) {
  if (value is! String) {
    throw const FormatException('Expected ISO-8601 timestamp');
  }
  return DateTime.parse(value).toUtc();
}
