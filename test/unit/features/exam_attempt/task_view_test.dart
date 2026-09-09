import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

TaskView _taskFrom(Map<String, dynamic> json) {
  return TaskView.fromJson({
    'pinnedItemPublicId': 'item-1',
    'orderIndex': 0,
    'totalTasks': 5,
    'section': 'READING',
    'taskType': 'MC_READING_SINGLE',
    'title': 'title',
    'prepSeconds': 0,
    'responseSeconds': 60,
    ...json,
  });
}

void main() {
  group('TaskOption.fromJson — orderIndex tolerance', () {
    test('accepts a JSON string orderIndex and keeps it as-is', () {
      final option = TaskOption.fromJson({'text': 'A', 'orderIndex': '2'});
      expect(option.orderIndex, '2');
    });

    test('accepts a JSON number orderIndex and normalizes to String', () {
      final option = TaskOption.fromJson({'text': 'A', 'orderIndex': 2});
      expect(option.orderIndex, '2');
      expect(option.orderIndex, isA<String>());
    });
  });

  group('BlankGroup.fromJson', () {
    test('round-trips blankIndex and its options', () {
      final group = BlankGroup.fromJson({
        'blankIndex': 1,
        'options': [
          {'text': 'quickly', 'orderIndex': 0},
          {'text': 'slowly', 'orderIndex': '1'},
        ],
      });

      expect(group.blankIndex, 1);
      expect(group.options, hasLength(2));
      expect(group.options[0].text, 'quickly');
      expect(group.options[0].orderIndex, '0');
      expect(group.options[1].orderIndex, '1');
    });
  });

  group('TaskView.fromJson — blankGroups', () {
    test('parses as null when absent from JSON', () {
      final task = _taskFrom({});
      expect(task.blankGroups, isNull);
    });

    test('parses correctly when present', () {
      final task = _taskFrom({
        'blankGroups': [
          {
            'blankIndex': 0,
            'options': [
              {'text': 'a', 'orderIndex': 0},
            ],
          },
        ],
      });

      expect(task.blankGroups, hasLength(1));
      expect(task.blankGroups!.single.blankIndex, 0);
    });

    test('options and blankGroups are independently nullable', () {
      final task = _taskFrom({
        'options': [
          {'text': 'a', 'orderIndex': 0},
        ],
      });

      expect(task.options, hasLength(1));
      expect(task.blankGroups, isNull);
    });
  });

  group('TaskView.fromJson — imageUrl (plans/phat-describe-image-e2e)', () {
    test('parses as null when absent from JSON', () {
      final task = _taskFrom({});
      expect(task.imageUrl, isNull);
    });

    test('parses correctly when present, independently of imagePromptRef', () {
      final task = _taskFrom({
        'imagePromptRef': 'raw-media-object-uuid',
        'imageUrl': 'https://example.com/resolved-image.png',
      });

      expect(task.imagePromptRef, 'raw-media-object-uuid');
      expect(task.imageUrl, 'https://example.com/resolved-image.png');
    });
  });
}
