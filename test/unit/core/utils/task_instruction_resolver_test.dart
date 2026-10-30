import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';
import 'package:pte_app/core/utils/task_instruction_resolver.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/task_view_ui_adapter.dart';

void main() {
  final readAloud = TaskTypeMeta.forTaskType(TaskTypeCodes.readAloud)!;

  group('resolveTaskInstruction', () {
    test('prefers the trimmed API instruction', () {
      expect(
        resolveTaskInstruction(
          apiInstruction: '  Read it slowly.  ',
          meta: readAloud,
        ),
        'Read it slowly.',
      );
    });

    test(
      'falls back to the built-in instruction when the API value is blank',
      () {
        for (final apiInstruction in [null, '', '   ']) {
          expect(
            resolveTaskInstruction(
              apiInstruction: apiInstruction,
              meta: readAloud,
            ),
            readAloud.instruction,
          );
        }
      },
    );

    test(
      'uses the caller fallback, then the app default, without metadata',
      () {
        expect(
          resolveTaskInstruction(fallback: 'Screen default'),
          'Screen default',
        );
        expect(resolveTaskInstruction(), AppStrings.defaultTaskInstruction);
      },
    );
  });

  group('TaskViewUiAdapter instruction', () {
    TaskView task({String? taskTypeInstruction}) => TaskView(
      pinnedItemPublicId: 'item-1',
      orderIndex: 0,
      totalTasks: 1,
      section: 'SPEAKING',
      taskType: TaskTypeCodes.readAloud,
      title: 'Read aloud',
      promptText: 'Text',
      prepSeconds: 30,
      responseSeconds: 40,
      taskTypeInstruction: taskTypeInstruction,
    );

    test('shows the server instruction', () {
      final model = TaskViewUiAdapter.adapt(
        task(taskTypeInstruction: 'Admin edited text.'),
      );
      expect(model.instruction, 'Admin edited text.');
    });

    test('keeps the built-in text for older responses', () {
      expect(
        TaskViewUiAdapter.adapt(task()).instruction,
        readAloud.instruction,
      );
    });
  });
}
