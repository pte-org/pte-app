import '../../domain/session_types.dart';

class SessionModel {
  const SessionModel({
    required this.publicId,
    required this.name,
    required this.tenantId,
    required this.snapshotPublicId,
    required this.opensAt,
    required this.closesAt,
    required this.status,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    publicId: json['publicId'] as String,
    name: json['name'] as String,
    tenantId: json['tenantId'] as String?,
    snapshotPublicId: json['snapshotPublicId'] as String,
    opensAt: DateTime.parse(json['opensAt'] as String).toUtc(),
    closesAt: DateTime.parse(json['closesAt'] as String).toUtc(),
    status: SessionStatus.fromWire(json['status'] as String),
  );

  final String publicId;
  final String name;
  final String? tenantId;
  final String snapshotPublicId;
  final DateTime opensAt;
  final DateTime closesAt;
  final SessionStatus status;

  ExamSession toEntity() => ExamSession(
    publicId: publicId,
    name: name,
    tenantId: tenantId,
    snapshotPublicId: snapshotPublicId,
    opensAt: opensAt,
    closesAt: closesAt,
    status: status,
  );
}
