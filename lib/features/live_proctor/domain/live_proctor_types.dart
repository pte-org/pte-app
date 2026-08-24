enum ViolationType {
  tabSwitch('TAB_SWITCH'),
  multipleFaces('MULTIPLE_FACES'),
  faceNotVisible('FACE_NOT_VISIBLE'),
  suspiciousAudio('SUSPICIOUS_AUDIO'),
  technicalIssue('TECHNICAL_ISSUE'),
  other('OTHER');

  const ViolationType(this.wireName);

  factory ViolationType.fromWire(String value) =>
      values.firstWhere((type) => type.wireName == value);

  final String wireName;
}

enum ProctorCommandType {
  forceSubmit('FORCE_SUBMIT'),
  extendTime('EXTEND_TIME');

  const ProctorCommandType(this.wireName);

  final String wireName;
}

class ProctorSession {
  const ProctorSession({
    required this.publicId,
    required this.sessionPublicId,
    required this.status,
    required this.openedAt,
  });

  final String publicId;
  final String sessionPublicId;
  final String status;
  final DateTime openedAt;
}

class AssignedProctorSession {
  const AssignedProctorSession({
    required this.assignmentPublicId,
    required this.sessionPublicId,
    required this.name,
    required this.opensAt,
    required this.closesAt,
    required this.status,
  });

  final String assignmentPublicId;
  final String sessionPublicId;
  final String name;
  final DateTime opensAt;
  final DateTime closesAt;
  final String status;
}

class ViolationEvent {
  const ViolationEvent({
    required this.publicId,
    required this.attemptPublicId,
    required this.type,
    required this.detail,
    required this.sequenceNo,
    required this.hash,
    required this.detectedAt,
  });

  final String publicId;
  final String attemptPublicId;
  final ViolationType type;
  final String? detail;
  final int sequenceNo;
  final String hash;
  final DateTime detectedAt;
}
