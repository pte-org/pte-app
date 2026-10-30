import 'package:pte_app/core/constants/task_type_meta.dart';

class PreviewSnapshot {
  const PreviewSnapshot({
    required this.snapshotPublicId,
    required this.name,
    required this.version,
    required this.items,
  });

  final String snapshotPublicId;
  final String name;
  final int version;
  final List<PreviewItem> items;
}

class PreviewItem {
  const PreviewItem({
    required this.orderIndex,
    required this.snapshotItemPublicId,
    required this.sourceQuestionPublicId,
    required this.section,
    required this.taskType,
    required this.taskTypeCode,
    required this.taskTypeDisplayName,
    required this.title,
    required this.promptText,
    required this.audioUrl,
    required this.imageUrl,
    required this.minWordCount,
    required this.maxWordCount,
    required this.options,
    required this.runtime,
    required this.runtimeMappingVersion,
    required this.runtimeMappingStatus,
    required this.prepSeconds,
    required this.responseSeconds,
    required this.preListenSeconds,
    required this.preRecordSeconds,
    required this.audioDurationSeconds,
    required this.audioUrlExpiresAt,
    required this.imageUrlExpiresAt,
    this.taskTypeInstruction,
  });

  final int orderIndex;
  final String snapshotItemPublicId;
  final String? sourceQuestionPublicId;
  final String section;
  final String? taskType;
  final String? taskTypeCode;
  final String? taskTypeDisplayName;
  final String? title;
  final String? promptText;
  final String? audioUrl;
  final String? imageUrl;
  final int? minWordCount;
  final int? maxWordCount;
  final List<PreviewOption> options;
  final TaskRuntimeProfile? runtime;
  final String? runtimeMappingVersion;
  final String? runtimeMappingStatus;
  final int prepSeconds;
  final int responseSeconds;
  final int? preListenSeconds;
  final int? preRecordSeconds;
  final int? audioDurationSeconds;
  final DateTime? audioUrlExpiresAt;
  final DateTime? imageUrlExpiresAt;

  /// Admin-editable instruction; null on older snapshots, where the UI falls back to [TaskTypeMeta.instruction].
  final String? taskTypeInstruction;
}

class PreviewOption {
  const PreviewOption({
    required this.orderIndex,
    required this.blankIndex,
    required this.text,
  });

  final int orderIndex;
  final int? blankIndex;
  final String text;
}
