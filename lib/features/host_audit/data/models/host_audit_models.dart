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
    required this.sequenceNo,
    required this.hash,
    required this.detectedAt,
  });

  factory ViolationAuditModel.fromJson(Map<String, dynamic> json) {
    return ViolationAuditModel(
      publicId: json['publicId'] as String,
      attemptPublicId: json['attemptPublicId'] as String,
      violationType: json['violationType'] as String,
      detail: json['detail'] as String,
      sequenceNo: json['sequenceNo'] as int,
      hash: json['hash'] as String,
      detectedAt: _requiredTimestamp(json['detectedAt']),
    );
  }

  final String publicId;
  final String attemptPublicId;
  final String violationType;
  final String detail;
  final int sequenceNo;
  final String hash;
  final DateTime detectedAt;

  ViolationAuditEvent toEntity() => ViolationAuditEvent(
    publicId: publicId,
    attemptPublicId: attemptPublicId,
    violationType: violationType,
    detail: detail,
    sequenceNo: sequenceNo,
    hash: hash,
    detectedAt: detectedAt,
  );
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
