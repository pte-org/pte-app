import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/features/exam_preview/data/models/preview_snapshot_model.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';

Map<String, dynamic> _itemJson(Object? taskTypeInstruction) => {
  'orderIndex': 0,
  'snapshotItemPublicId': 'item-1',
  'section': 'READING',
  'taskType': TaskTypeCodes.mcReadingSingle,
  'taskTypeCode': TaskTypeCodes.mcReadingSingle,
  'title': 'Question',
  'prepSeconds': 0,
  'responseSeconds': 60,
  'taskTypeInstruction': ?taskTypeInstruction,
};

void main() {
  group('PreviewItemModel.fromJson taskTypeInstruction', () {
    test('parses the trimmed instruction', () {
      final item = PreviewItemModel.fromJson(_itemJson('  Pick one answer.  '));
      expect(item.taskTypeInstruction, 'Pick one answer.');
    });

    test('treats a missing or blank instruction as null', () {
      expect(
        PreviewItemModel.fromJson(_itemJson(null)).taskTypeInstruction,
        isNull,
      );
      expect(
        PreviewItemModel.fromJson(_itemJson('  ')).taskTypeInstruction,
        isNull,
      );
    });
  });

  group('host preview instruction', () {
    test('shows the server instruction, else the built-in text', () {
      final edited = PreviewTaskUiAdapter.adapt(
        PreviewItemModel.fromJson(_itemJson('Pick one answer.')),
      );
      final older = PreviewTaskUiAdapter.adapt(
        PreviewItemModel.fromJson(_itemJson(null)),
      );

      expect(edited.instruction, 'Pick one answer.');
      expect(
        older.instruction,
        TaskTypeMeta.forTaskType(TaskTypeCodes.mcReadingSingle)!.instruction,
      );
    });
  });
}
