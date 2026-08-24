import '../../domain/authoring_types.dart';
import '../../domain/blueprint_types.dart';

class BlueprintModel {
  BlueprintModel({
    required this.publicId,
    required this.name,
    required this.tenantId,
    required this.status,
    required this.items,
  });

  factory BlueprintModel.fromJson(Map<String, dynamic> json) {
    return BlueprintModel(
      publicId: json['publicId'] as String,
      name: json['name'] as String,
      tenantId: json['tenantId'] as String?,
      status: json['status'] as String,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) => BlueprintItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String publicId;
  final String name;
  final String? tenantId;
  final String status;
  final List<BlueprintItemModel> items;

  Blueprint toEntity() => Blueprint(
    publicId: publicId,
    name: name,
    tenantId: tenantId,
    status: status,
    items: items.map((item) => item.toEntity()).toList(growable: false),
  );
}

class BlueprintItemModel {
  const BlueprintItemModel({
    required this.questionPublicId,
    required this.section,
    required this.orderIndex,
  });

  factory BlueprintItemModel.fromJson(Map<String, dynamic> json) =>
      BlueprintItemModel(
        questionPublicId: json['questionPublicId'] as String,
        section: json['section'] as String,
        orderIndex: json['orderIndex'] as int,
      );

  final String questionPublicId;
  final String section;
  final int orderIndex;

  BlueprintItem toEntity() => BlueprintItem(
    questionPublicId: questionPublicId,
    section: section,
    orderIndex: orderIndex,
  );
}

class SnapshotModel {
  SnapshotModel({
    required this.publicId,
    required this.name,
    required this.version,
    required this.sourceBlueprintPublicId,
    required this.tenantId,
    required this.items,
  });

  factory SnapshotModel.fromJson(Map<String, dynamic> json) => SnapshotModel(
    publicId: json['publicId'] as String,
    name: json['name'] as String,
    version: json['version'] as int,
    sourceBlueprintPublicId: json['sourceBlueprintPublicId'] as String,
    tenantId: json['tenantId'] as String?,
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((item) => SnapshotItemModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  final String publicId;
  final String name;
  final int version;
  final String sourceBlueprintPublicId;
  final String? tenantId;
  final List<SnapshotItemModel> items;

  ExamSnapshot toEntity() => ExamSnapshot(
    publicId: publicId,
    name: name,
    version: version,
    sourceBlueprintPublicId: sourceBlueprintPublicId,
    tenantId: tenantId,
    items: items.map((item) => item.toEntity()).toList(growable: false),
  );
}

class SnapshotItemModel {
  const SnapshotItemModel({
    required this.orderIndex,
    required this.section,
    required this.taskType,
    required this.title,
  });

  factory SnapshotItemModel.fromJson(Map<String, dynamic> json) =>
      SnapshotItemModel(
        orderIndex: json['orderIndex'] as int,
        section: json['section'] as String,
        taskType: PteTaskType.values.firstWhere(
          (type) => type.wireName == json['taskType'],
          orElse: () =>
              throw FormatException('Unknown task type: ${json['taskType']}'),
        ),
        title: json['title'] as String,
      );

  final int orderIndex;
  final String section;
  final PteTaskType taskType;
  final String title;

  SnapshotItem toEntity() => SnapshotItem(
    orderIndex: orderIndex,
    section: section,
    taskType: taskType,
    title: title,
  );
}
