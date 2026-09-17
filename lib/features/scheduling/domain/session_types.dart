class SchedulingValidationException implements Exception {
  const SchedulingValidationException(this.message);

  final String message;
}

enum SessionStatus {
  scheduled,
  open,
  closed;

  static SessionStatus fromWire(String value) => switch (value) {
    'SCHEDULED' => scheduled,
    'OPEN' => open,
    'CLOSED' => closed,
    _ => throw FormatException('Unsupported session status: $value'),
  };

  String get wireName => name.toUpperCase();
  bool get canOpen => this == scheduled;
  bool get canClose => this == open;
  /// Assign/unassign a Class is only allowed while the exam hasn't opened yet (Plan B, Phase 4).
  bool get isScheduled => this == scheduled;
}

/// The 4 PTE sections a host picks from to generate an exam (Plan B) — the
/// backend randomly draws the question set for these skills from the bank.
enum ExamSkill {
  speaking,
  writing,
  reading,
  listening;

  String get wireName => name.toUpperCase();
}

class CreateSessionInput {
  CreateSessionInput({
    required this.name,
    required Set<ExamSkill> skills,
    required this.opensAt,
    required this.closesAt,
  }) : skills = Set.unmodifiable(skills);

  final String name;
  final Set<ExamSkill> skills;
  final DateTime opensAt;
  final DateTime closesAt;

  CreateSessionInput normalized({required DateTime now}) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || skills.isEmpty || skills.length > 4) {
      throw const SchedulingValidationException(
        'Session name and 1 to 4 skills are required.',
      );
    }
    if (!opensAt.isAfter(now) || !closesAt.isAfter(opensAt)) {
      throw const SchedulingValidationException(
        'Open time must be in the future and close time must be later.',
      );
    }
    return CreateSessionInput(
      name: normalizedName,
      skills: skills,
      opensAt: opensAt.toUtc(),
      closesAt: closesAt.toUtc(),
    );
  }
}

class ExamSession {
  const ExamSession({
    required this.publicId,
    required this.name,
    required this.tenantId,
    required this.snapshotPublicId,
    required this.opensAt,
    required this.closesAt,
    required this.status,
  });

  final String publicId;
  final String name;
  final String? tenantId;
  final String snapshotPublicId;
  final DateTime opensAt;
  final DateTime closesAt;
  final SessionStatus status;
}

/// A Class (from `enrollment`, referenced by `publicId`) assigned to a
/// session — matches the backend's `SessionClassAssignmentResponse`
/// exactly. `pte-app` has no Class-browsing screen of its own (unlike
/// `tenant-web`), so the host enters the target `classPublicId` directly,
/// same input style as the pre-existing session/snapshot ID fields.
class AssignedClass {
  const AssignedClass({required this.sessionPublicId, required this.classPublicId});

  final String sessionPublicId;
  final String classPublicId;
}
