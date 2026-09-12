import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_catalog.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/exam_task_ui_model.dart';

void main() {
  test('catalog covers every registered task type exactly once', () {
    final models = ExamUiPreviewCatalog.models;
    expect(models, hasLength(23));
    expect(models.map((model) => model.taskType).toSet(), hasLength(23));
    expect(TaskTypeMeta.all, hasLength(23));
    expect(models.every((model) => model.isComplete), isTrue);
    expect(models.every((model) => model.origin == DataOrigin.fixture), isTrue);
  });

  test('adapter keeps compound audio and text stimulus parts', () {
    final model = ExamUiPreviewCatalog.modelFor('SUMMARIZE_GROUP_DISCUSSION');
    expect(model.stimulus.isCompound, isTrue);
    expect(
      model.stimulus.parts.map((part) => part.kind),
      containsAll(<StimulusPartKind>[
        StimulusPartKind.audio,
        StimulusPartKind.text,
      ]),
    );
  });
}
