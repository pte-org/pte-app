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
    required this.composition,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    publicId: json['publicId'] as String,
    name: json['name'] as String,
    tenantId: json['tenantId'] as String?,
    snapshotPublicId: json['snapshotPublicId'] as String,
    opensAt: DateTime.parse(json['opensAt'] as String).toUtc(),
    closesAt: DateTime.parse(json['closesAt'] as String).toUtc(),
    status: SessionStatus.fromWire(json['status'] as String),
    composition: ((json['composition'] as List<dynamic>?) ?? const [])
        .map(
          (item) => CompositionItemModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false),
  );

  final String publicId;
  final String name;
  final String? tenantId;
  final String snapshotPublicId;
  final DateTime opensAt;
  final DateTime closesAt;
  final SessionStatus status;
  final List<CompositionItemModel> composition;

  ExamSession toEntity() => ExamSession(
    publicId: publicId,
    name: name,
    tenantId: tenantId,
    snapshotPublicId: snapshotPublicId,
    opensAt: opensAt,
    closesAt: closesAt,
    status: status,
    composition: composition.map((item) => item.toEntity()).toList(),
  );
}

class CompositionItemModel {
  const CompositionItemModel({
    required this.taskType,
    required this.section,
    required this.orderIndex,
    required this.timingOverrideSeconds,
  });

  factory CompositionItemModel.fromJson(Map<String, dynamic> json) =>
      CompositionItemModel(
        taskType: json['taskType'] as String,
        section: json['section'] as String,
        orderIndex: json['orderIndex'] as int,
        timingOverrideSeconds: json['timingOverrideSeconds'] as int?,
      );

  final String taskType;
  final String section;
  final int orderIndex;
  final int? timingOverrideSeconds;

  SessionCompositionItem toEntity() => SessionCompositionItem(
    taskType: taskType,
    section: section,
    orderIndex: orderIndex,
    timingOverrideSeconds: timingOverrideSeconds,
  );
}
