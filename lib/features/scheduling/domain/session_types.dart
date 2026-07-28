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
}

class CreateSessionInput {
  const CreateSessionInput({
    required this.name,
    required this.snapshotPublicId,
    required this.opensAt,
    required this.closesAt,
  });

  final String name;
  final String snapshotPublicId;
  final DateTime opensAt;
  final DateTime closesAt;

  CreateSessionInput normalized({required DateTime now}) {
    final normalizedName = name.trim();
    final normalizedSnapshotId = snapshotPublicId.trim();
    if (normalizedName.isEmpty || normalizedSnapshotId.isEmpty) {
      throw const SchedulingValidationException(
        'Session name and snapshot ID are required.',
      );
    }
    if (!opensAt.isAfter(now) || !closesAt.isAfter(opensAt)) {
      throw const SchedulingValidationException(
        'Open time must be in the future and close time must be later.',
      );
    }
    return CreateSessionInput(
      name: normalizedName,
      snapshotPublicId: normalizedSnapshotId,
      opensAt: opensAt.toUtc(),
      closesAt: closesAt.toUtc(),
    );
  }
}

class CompositionItemInput {
  const CompositionItemInput({
    required this.taskType,
    required this.section,
    required this.orderIndex,
    this.timingOverrideSeconds,
  });

  final String taskType;
  final String section;
  final int orderIndex;
  final int? timingOverrideSeconds;
}

class SetCompositionInput {
  SetCompositionInput({required List<CompositionItemInput> items})
    : items = List.unmodifiable(items);

  final List<CompositionItemInput> items;

  SetCompositionInput normalized() {
    if (items.isEmpty) {
      throw const SchedulingValidationException(
        'Composition needs at least one task type.',
      );
    }
    final taskTypes = items.map((item) => item.taskType.trim()).toSet();
    if (taskTypes.length != items.length) {
      throw const SchedulingValidationException(
        'A task type can appear only once in a composition.',
      );
    }
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final invalidTiming =
          item.timingOverrideSeconds != null &&
          item.timingOverrideSeconds! <= 0;
      if (item.taskType.trim().isEmpty ||
          item.section.trim().isEmpty ||
          item.orderIndex != index ||
          invalidTiming) {
        throw const SchedulingValidationException(
          'Composition items must be complete and contiguously ordered.',
        );
      }
    }
    return SetCompositionInput(items: items);
  }
}

class SessionCompositionItem {
  const SessionCompositionItem({
    required this.taskType,
    required this.section,
    required this.orderIndex,
    this.timingOverrideSeconds,
  });

  final String taskType;
  final String section;
  final int orderIndex;
  final int? timingOverrideSeconds;
}

class ExamSession {
  ExamSession({
    required this.publicId,
    required this.name,
    required this.tenantId,
    required this.snapshotPublicId,
    required this.opensAt,
    required this.closesAt,
    required this.status,
    required List<SessionCompositionItem> composition,
  }) : composition = List.unmodifiable(composition);

  final String publicId;
  final String name;
  final String? tenantId;
  final String snapshotPublicId;
  final DateTime opensAt;
  final DateTime closesAt;
  final SessionStatus status;
  final List<SessionCompositionItem> composition;
}

class SnapshotTaskOption {
  const SnapshotTaskOption({
    required this.taskType,
    required this.section,
    required this.title,
  });

  final String taskType;
  final String section;
  final String title;
}
