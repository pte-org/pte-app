import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/authoring/data/models/blueprint_models.dart';
import 'package:pte_app/features/authoring/domain/blueprint_types.dart';
import 'package:pte_app/features/authoring/domain/authoring_types.dart';

void main() {
  test(
    'CreateBlueprintInput trims name and requires contiguous nonempty items',
    () {
      final normalized = CreateBlueprintInput(
        name: '  Mock exam  ',
        items: const [
          BlueprintItemInput(
            questionPublicId: 'q-1',
            section: 'READING',
            orderIndex: 0,
          ),
          BlueprintItemInput(
            questionPublicId: 'q-2',
            section: 'WRITING',
            orderIndex: 1,
          ),
        ],
      ).normalized();

      expect(normalized.name, 'Mock exam');
      expect(normalized.items.map((item) => item.orderIndex), [0, 1]);
    },
  );

  test(
    'CreateBlueprintInput rejects empty and duplicate question composition',
    () {
      expect(
        () => CreateBlueprintInput(name: 'Exam', items: const []).normalized(),
        throwsA(isA<AuthoringValidationException>()),
      );
      expect(
        () => CreateBlueprintInput(
          name: 'Exam',
          items: const [
            BlueprintItemInput(
              questionPublicId: 'q-1',
              section: 'READING',
              orderIndex: 0,
            ),
            BlueprintItemInput(
              questionPublicId: 'q-1',
              section: 'READING',
              orderIndex: 1,
            ),
          ],
        ).normalized(),
        throwsA(isA<AuthoringValidationException>()),
      );
    },
  );

  test('Blueprint and Snapshot models parse ordered backend responses', () {
    final blueprint = BlueprintModel.fromJson({
      'publicId': 'bp-1',
      'name': 'Exam',
      'tenantId': 'tenant-1',
      'status': 'DRAFT',
      'items': [
        {'questionPublicId': 'q-1', 'section': 'READING', 'orderIndex': 0},
      ],
    }).toEntity();
    final snapshot = SnapshotModel.fromJson({
      'publicId': 'snap-1',
      'name': 'Exam',
      'version': 1,
      'sourceBlueprintPublicId': 'bp-1',
      'tenantId': 'tenant-1',
      'items': [
        {
          'orderIndex': 0,
          'section': 'READING',
          'taskType': 'MC_READING_SINGLE',
          'title': 'Question',
        },
      ],
    }).toEntity();

    expect(blueprint.items.single.questionPublicId, 'q-1');
    expect(snapshot.version, 1);
    expect(snapshot.items.single.taskType, PteTaskType.mcReadingSingle);
  });
}
