import '../../domain/live_proctor_types.dart';

class AssignedProctorSessionModel {
  const AssignedProctorSessionModel({
    required this.assignmentPublicId,
    required this.sessionPublicId,
    required this.name,
    required this.opensAt,
    required this.closesAt,
    required this.status,
  });

  factory AssignedProctorSessionModel.fromJson(Map<String, dynamic> json) =>
      AssignedProctorSessionModel(
        assignmentPublicId: json['assignmentPublicId'] as String,
        sessionPublicId: json['sessionPublicId'] as String,
        name: json['name'] as String,
        opensAt: DateTime.parse(json['opensAt'] as String).toUtc(),
        closesAt: DateTime.parse(json['closesAt'] as String).toUtc(),
        status: json['status'] as String,
      );

  final String assignmentPublicId;
  final String sessionPublicId;
  final String name;
  final DateTime opensAt;
  final DateTime closesAt;
  final String status;

  AssignedProctorSession toEntity() => AssignedProctorSession(
    assignmentPublicId: assignmentPublicId,
    sessionPublicId: sessionPublicId,
    name: name,
    opensAt: opensAt,
    closesAt: closesAt,
    status: status,
  );
}

class ViolationEventModel {
  const ViolationEventModel({
    required this.publicId,
    required this.attemptPublicId,
    required this.type,
    required this.detail,
    required this.sequenceNo,
    required this.hash,
    required this.detectedAt,
  });

  factory ViolationEventModel.fromJson(Map<String, dynamic> json) =>
      ViolationEventModel(
        publicId: json['publicId'] as String,
        attemptPublicId: json['attemptPublicId'] as String,
        type: ViolationType.fromWire(json['violationType'] as String),
        detail: json['detail'] as String?,
        sequenceNo: json['sequenceNo'] as int,
        hash: json['hash'] as String,
        detectedAt: DateTime.parse(json['detectedAt'] as String).toUtc(),
      );

  final String publicId;
  final String attemptPublicId;
  final ViolationType type;
  final String? detail;
  final int sequenceNo;
  final String hash;
  final DateTime detectedAt;

  ViolationEvent toEntity() => ViolationEvent(
    publicId: publicId,
    attemptPublicId: attemptPublicId,
    type: type,
    detail: detail,
    sequenceNo: sequenceNo,
    hash: hash,
    detectedAt: detectedAt,
  );
}
