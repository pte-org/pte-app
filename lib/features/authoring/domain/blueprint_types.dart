import 'authoring_types.dart';

class BlueprintItemInput {
  const BlueprintItemInput({
    required this.questionPublicId,
    required this.section,
    required this.orderIndex,
  });

  final String questionPublicId;
  final String section;
  final int orderIndex;
}

class CreateBlueprintInput {
  CreateBlueprintInput({
    required this.name,
    required List<BlueprintItemInput> items,
  }) : items = List.unmodifiable(items);

  final String name;
  final List<BlueprintItemInput> items;

  CreateBlueprintInput normalized() {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || items.isEmpty) {
      throw const AuthoringValidationException(
        'Blueprint name and at least one question are required.',
      );
    }
    final questionIds = items.map((item) => item.questionPublicId).toSet();
    if (questionIds.length != items.length) {
      throw const AuthoringValidationException(
        'A question can appear only once in a blueprint.',
      );
    }
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item.questionPublicId.trim().isEmpty ||
          item.section.trim().isEmpty ||
          item.orderIndex != index) {
        throw const AuthoringValidationException(
          'Blueprint items must be complete and contiguously ordered.',
        );
      }
    }
    return CreateBlueprintInput(name: normalizedName, items: items);
  }
}

class BlueprintItem {
  const BlueprintItem({
    required this.questionPublicId,
    required this.section,
    required this.orderIndex,
  });

  final String questionPublicId;
  final String section;
  final int orderIndex;
}

class Blueprint {
  Blueprint({
    required this.publicId,
    required this.name,
    required this.tenantId,
    required this.status,
    required List<BlueprintItem> items,
  }) : items = List.unmodifiable(items);

  final String publicId;
  final String name;
  final String? tenantId;
  final String status;
  final List<BlueprintItem> items;
}

class SnapshotItem {
  const SnapshotItem({
    required this.orderIndex,
    required this.section,
    required this.taskType,
    required this.title,
  });

  final int orderIndex;
  final String section;
  final PteTaskType taskType;
  final String title;
}

class ExamSnapshot {
  ExamSnapshot({
    required this.publicId,
    required this.name,
    required this.version,
    required this.sourceBlueprintPublicId,
    required this.tenantId,
    required List<SnapshotItem> items,
  }) : items = List.unmodifiable(items);

  final String publicId;
  final String name;
  final int version;
  final String sourceBlueprintPublicId;
  final String? tenantId;
  final List<SnapshotItem> items;
}
