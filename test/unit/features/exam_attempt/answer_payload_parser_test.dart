import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/domain/answer_payload_parser.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';

TaskOption option(String index) => TaskOption(text: 'text-$index', orderIndex: index);

void main() {
  group('singleSelectionFromAnswerPayload', () {
    test('returns the stored value as it is', () {
      expect(singleSelectionFromAnswerPayload('2'), '2');
    });

    test('returns null for a missing or empty payload', () {
      expect(singleSelectionFromAnswerPayload(null), isNull);
      expect(singleSelectionFromAnswerPayload(''), isNull);
    });
  });

  group('optionIndexesFromAnswerPayload', () {
    test('splits a comma list into a set', () {
      expect(optionIndexesFromAnswerPayload('0,2,3'), {'0', '2', '3'});
    });

    test('drops empty parts and duplicates', () {
      expect(optionIndexesFromAnswerPayload('1,,1,2,'), {'1', '2'});
    });

    test('returns an empty set for null or empty', () {
      expect(optionIndexesFromAnswerPayload(null), isEmpty);
      expect(optionIndexesFromAnswerPayload(''), isEmpty);
    });
  });

  group('indicesFromAnswerPayload', () {
    test('keeps valid non negative integers', () {
      expect(indicesFromAnswerPayload('0,4,2'), {0, 4, 2});
    });

    test('ignores text and negative numbers', () {
      expect(indicesFromAnswerPayload('a,-1,3,,x2'), {3});
    });

    test('returns an empty set for null or empty', () {
      expect(indicesFromAnswerPayload(null), isEmpty);
      expect(indicesFromAnswerPayload(''), isEmpty);
    });
  });

  group('positionalValuesFromAnswerPayload', () {
    test('returns exactly length values, padding missing positions with empty text', () {
      expect(positionalValuesFromAnswerPayload('a,b', length: 4), ['a', 'b', '', '']);
    });

    test('cuts values beyond the requested length', () {
      expect(positionalValuesFromAnswerPayload('a,b,c', length: 2), ['a', 'b']);
    });

    test('keeps empty positions in the middle', () {
      expect(positionalValuesFromAnswerPayload('a,,c', length: 3), ['a', '', 'c']);
    });

    test('returns an empty list for a zero or negative length', () {
      expect(positionalValuesFromAnswerPayload('a', length: 0), isEmpty);
      expect(positionalValuesFromAnswerPayload('a', length: -2), isEmpty);
    });

    test('pads everything for a null payload', () {
      expect(positionalValuesFromAnswerPayload(null, length: 2), ['', '']);
    });
  });

  group('positionalSelectionsFromAnswerPayload', () {
    test('turns empty positions into null', () {
      expect(positionalSelectionsFromAnswerPayload('x,,z', length: 4), ['x', null, 'z', null]);
    });
  });

  group('reorderedOptionsFromAnswerPayload', () {
    final defaults = [option('0'), option('1'), option('2')];

    test('restores the saved order', () {
      final result = reorderedOptionsFromAnswerPayload(defaultOrder: defaults, payload: '2,0,1');

      expect(result.map((o) => o.orderIndex), ['2', '0', '1']);
    });

    test('keeps the default order for a missing or empty payload', () {
      expect(reorderedOptionsFromAnswerPayload(defaultOrder: defaults, payload: null), same(defaults));
      expect(reorderedOptionsFromAnswerPayload(defaultOrder: defaults, payload: ''), same(defaults));
    });

    test('keeps the default order when the payload has a different count', () {
      expect(reorderedOptionsFromAnswerPayload(defaultOrder: defaults, payload: '0,1'), same(defaults));
      expect(reorderedOptionsFromAnswerPayload(defaultOrder: defaults, payload: '0,1,2,0'), same(defaults));
    });

    test('keeps the default order when an index repeats', () {
      expect(reorderedOptionsFromAnswerPayload(defaultOrder: defaults, payload: '0,0,1'), same(defaults));
    });

    test('keeps the default order when an index does not belong to the options', () {
      expect(reorderedOptionsFromAnswerPayload(defaultOrder: defaults, payload: '0,1,9'), same(defaults));
    });

    test('returns the empty default list as it is', () {
      const empty = <TaskOption>[];
      expect(reorderedOptionsFromAnswerPayload(defaultOrder: empty, payload: '0'), same(empty));
    });
  });

  group('gapAssignmentsFromAnswerPayload', () {
    final options = [option('0'), option('1'), option('2')];

    test('assigns each gap the option written at its position', () {
      final result = gapAssignmentsFromAnswerPayload(payload: '2,0', gapCount: 2, options: options);

      expect(result.map((gap, o) => MapEntry(gap, o.orderIndex)), {0: '2', 1: '0'});
    });

    test('leaves a gap empty when its position is blank or beyond the payload', () {
      final result = gapAssignmentsFromAnswerPayload(payload: '1', gapCount: 3, options: options);

      expect(result.keys, [0]);
    });

    test('uses an option only once, in the first gap that names it', () {
      final result = gapAssignmentsFromAnswerPayload(payload: '1,1,2', gapCount: 3, options: options);

      expect(result.map((gap, o) => MapEntry(gap, o.orderIndex)), {0: '1', 2: '2'});
    });

    test('skips an option that does not exist', () {
      final result = gapAssignmentsFromAnswerPayload(payload: '7,0', gapCount: 2, options: options);

      expect(result.keys, [1]);
    });

    test('returns nothing for a null payload', () {
      expect(gapAssignmentsFromAnswerPayload(payload: null, gapCount: 2, options: options), isEmpty);
    });
  });
}
