import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/domain/attempt_preflight.dart';

void main() {
  group('AttemptPreflight.fromJson', () {
    test('reads a full answer', () {
      final preflight = AttemptPreflight.fromJson({
        'canStart': false,
        'missingCapabilities': ['MICROPHONE', 'LOCKDOWN'],
        'unsupportedTasks': [
          {
            'taskTypeKey': 'READ_ALOUD',
            'screenKey': 'speaking.read_aloud',
            'contractVersion': 2,
            'reasonCode': 'UNSUPPORTED_RUNTIME_CONTRACT',
            'userMessage': 'Update the app',
          },
        ],
        'code': 'PREFLIGHT_FAILED',
        'userMessage': 'Cannot start',
      });

      expect(preflight.canStart, isFalse);
      expect(preflight.missingCapabilities, ['MICROPHONE', 'LOCKDOWN']);
      expect(preflight.unsupportedTasks.single.taskTypeKey, 'READ_ALOUD');
      expect(preflight.unsupportedTasks.single.contractVersion, 2);
      expect(preflight.code, 'PREFLIGHT_FAILED');
      expect(preflight.userMessage, 'Cannot start');
    });

    test('canStart is true only for a real true', () {
      expect(AttemptPreflight.fromJson({'canStart': true}).canStart, isTrue);
      expect(AttemptPreflight.fromJson({'canStart': 'true'}).canStart, isFalse);
      expect(AttemptPreflight.fromJson({'canStart': 1}).canStart, isFalse);
      expect(AttemptPreflight.fromJson({}).canStart, isFalse);
    });

    test('uses empty lists when the lists are missing or not lists', () {
      final missing = AttemptPreflight.fromJson({'canStart': true});
      final wrong = AttemptPreflight.fromJson({'missingCapabilities': 'MIC', 'unsupportedTasks': {}});

      expect(missing.missingCapabilities, isEmpty);
      expect(missing.unsupportedTasks, isEmpty);
      expect(wrong.missingCapabilities, isEmpty);
      expect(wrong.unsupportedTasks, isEmpty);
    });

    test('keeps only text entries of the missing capability list', () {
      final preflight = AttemptPreflight.fromJson({
        'missingCapabilities': ['A', 1, null, 'B'],
      });

      expect(preflight.missingCapabilities, ['A', 'B']);
    });

    test('keeps only object entries of the unsupported task list', () {
      final preflight = AttemptPreflight.fromJson({
        'unsupportedTasks': [
          'junk',
          {'taskTypeKey': 'X'},
          7,
        ],
      });

      expect(preflight.unsupportedTasks.map((task) => task.taskTypeKey), ['X']);
    });
  });

  group('UnsupportedTask.fromJson', () {
    test('accepts a contract version sent as a decimal number', () {
      expect(UnsupportedTask.fromJson({'contractVersion': 3.0}).contractVersion, 3);
    });

    test('ignores a contract version that is not a number', () {
      expect(UnsupportedTask.fromJson({'contractVersion': '3'}).contractVersion, isNull);
    });

    test('all fields are optional', () {
      final task = UnsupportedTask.fromJson({});

      expect(task.taskTypeKey, isNull);
      expect(task.screenKey, isNull);
      expect(task.reasonCode, isNull);
      expect(task.userMessage, isNull);
    });
  });
}
