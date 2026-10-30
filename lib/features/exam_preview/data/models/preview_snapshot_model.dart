import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';

import '../../domain/entities/preview_snapshot.dart';

class PreviewSnapshotModel extends PreviewSnapshot {
  const PreviewSnapshotModel({
    required super.snapshotPublicId,
    required super.name,
    required super.version,
    required super.items,
  });

  factory PreviewSnapshotModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException(ExamPreviewStrings.itemsRequired);
    }
    return PreviewSnapshotModel(
      snapshotPublicId: _requiredSnapshotString(json['snapshotPublicId']),
      name: _string(json['name']) ?? ExamPreviewStrings.previewTitle,
      version: _int(json['version']) ?? 0,
      items: rawItems
          .whereType<Map>()
          .map(
            (raw) => PreviewItemModel.fromJson(Map<String, dynamic>.from(raw)),
          )
          .toList(growable: false),
    );
  }
}

class PreviewItemModel extends PreviewItem {
  const PreviewItemModel({
    required super.orderIndex,
    required super.snapshotItemPublicId,
    required super.sourceQuestionPublicId,
    required super.section,
    required super.taskType,
    required super.taskTypeCode,
    required super.taskTypeDisplayName,
    required super.title,
    required super.promptText,
    required super.audioUrl,
    required super.imageUrl,
    required super.minWordCount,
    required super.maxWordCount,
    required super.options,
    required super.runtime,
    required super.runtimeMappingVersion,
    required super.runtimeMappingStatus,
    required super.prepSeconds,
    required super.responseSeconds,
    required super.preListenSeconds,
    required super.preRecordSeconds,
    required super.audioDurationSeconds,
    required super.audioUrlExpiresAt,
    required super.imageUrlExpiresAt,
    super.taskTypeInstruction,
  });

  factory PreviewItemModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final runtimeJson = json['runtime'];
    return PreviewItemModel(
      orderIndex: _int(json['orderIndex']) ?? 0,
      snapshotItemPublicId: _requiredSnapshotString(
        json['snapshotItemPublicId'],
      ),
      sourceQuestionPublicId: _string(json['sourceQuestionPublicId']),
      section: _string(json['section']) ?? 'UNKNOWN',
      taskType: _string(json['taskType']),
      taskTypeCode: _string(json['taskTypeCode']),
      taskTypeDisplayName: _string(json['taskTypeDisplayName']),
      title: _string(json['title']),
      promptText: _string(json['promptText']),
      audioUrl: _string(json['audioUrl']),
      imageUrl: _string(json['imageUrl']),
      minWordCount: _int(json['minWordCount']),
      maxWordCount: _int(json['maxWordCount']),
      options: rawOptions is List
          ? rawOptions
                .whereType<Map>()
                .map(
                  (raw) => PreviewOptionModel.fromJson(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList(growable: false)
          : const <PreviewOption>[],
      runtime: runtimeJson is Map
          ? TaskRuntimeProfile.fromJson(Map<String, dynamic>.from(runtimeJson))
          : null,
      runtimeMappingVersion: _string(json['runtimeMappingVersion']),
      runtimeMappingStatus: _string(json['runtimeMappingStatus']),
      prepSeconds: _int(json['prepSeconds']) ?? 0,
      responseSeconds: _int(json['responseSeconds']) ?? 0,
      preListenSeconds: _int(json['preListenSeconds']),
      preRecordSeconds: _int(json['preRecordSeconds']),
      audioDurationSeconds: _int(json['audioDurationSeconds']),
      audioUrlExpiresAt: _date(json['audioUrlExpiresAt']),
      imageUrlExpiresAt: _date(json['imageUrlExpiresAt']),
      taskTypeInstruction: _string(json['taskTypeInstruction']),
    );
  }
}

class PreviewOptionModel extends PreviewOption {
  const PreviewOptionModel({
    required super.orderIndex,
    required super.blankIndex,
    required super.text,
  });

  factory PreviewOptionModel.fromJson(Map<String, dynamic> json) {
    return PreviewOptionModel(
      orderIndex: _int(json['orderIndex']) ?? 0,
      blankIndex: _int(json['blankIndex']),
      text: _string(json['text']) ?? '',
    );
  }
}

String _requiredSnapshotString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) {
    throw const FormatException(ExamPreviewStrings.stableIdentifierRequired);
  }
  return normalized;
}

String? _string(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

int? _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
