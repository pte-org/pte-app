import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';

PreviewItem _item(String code, {String? promptText = 'Preview prompt'}) =>
    PreviewItem(
      orderIndex: 0,
      snapshotItemPublicId: 'item-$code',
      sourceQuestionPublicId: 'question-$code',
      section: TaskTypeMeta.forTaskType(code)?.section ?? 'UNKNOWN',
      taskType: code,
      taskTypeCode: code,
      taskTypeDisplayName: code,
      title: code,
      promptText: promptText,
      audioUrl: null,
      imageUrl: null,
      minWordCount: null,
      maxWordCount: null,
      options: const [
        PreviewOption(orderIndex: 0, blankIndex: 0, text: 'Option'),
      ],
      runtime: null,
      runtimeMappingVersion: null,
      runtimeMappingStatus: null,
      prepSeconds: 0,
      responseSeconds: 0,
      preListenSeconds: null,
      preRecordSeconds: null,
      audioDurationSeconds: null,
      audioUrlExpiresAt: null,
      imageUrlExpiresAt: null,
    );

void main() {
  test('the canonical registry resolves all 22 PTE task codes', () {
    final codes = TaskTypeMeta.all
        .where((meta) => meta.taskType != TaskTypeCodes.personalIntroduction)
        .map((meta) => meta.taskType)
        .toList();

    expect(codes, hasLength(22));
    for (final code in codes) {
      final model = PreviewTaskUiAdapter.adapt(_item(code));
      expect(model.isSupported, isTrue, reason: code);
      expect(model.meta?.taskType, code);
    }
  });

  test('unsupported runtime is explicit and never guessed into a renderer', () {
    final item = PreviewItem(
      orderIndex: 0,
      snapshotItemPublicId: 'item-1',
      sourceQuestionPublicId: null,
      section: 'READING',
      taskType: 'MC_READING_SINGLE',
      taskTypeCode: 'MC_READING_SINGLE',
      taskTypeDisplayName: 'Multiple choice',
      title: 'Question',
      promptText: 'Question',
      audioUrl: null,
      imageUrl: null,
      minWordCount: null,
      maxWordCount: null,
      options: const [],
      runtime: const TaskRuntimeProfile(
        taskTypeCode: 'MC_READING_SINGLE',
        taskTypeKey: 'MC_READING_SINGLE',
        screenKey: 'UNKNOWN_RENDERER_V99',
        contractVersion: 99,
        profileKey: 'unknown',
        profileVersion: 99,
        behaviorKey: 'unknown',
        rendererKey: 'UNKNOWN_RENDERER_V99',
        answerSchemaVersion: 99,
        scoringProfileKey: 'unknown',
        scoringProfileVersion: 99,
        status: 'ACTIVE',
      ),
      runtimeMappingVersion: 'v99',
      runtimeMappingStatus: 'ACTIVE',
      prepSeconds: 0,
      responseSeconds: 0,
      preListenSeconds: null,
      preRecordSeconds: null,
      audioDurationSeconds: null,
      audioUrlExpiresAt: null,
      imageUrlExpiresAt: null,
    );

    final model = PreviewTaskUiAdapter.adapt(item);

    expect(model.isSupported, isFalse);
    expect(model.resolution.failure, TaskTypeResolutionFailure.unknownRenderer);
  });
}
