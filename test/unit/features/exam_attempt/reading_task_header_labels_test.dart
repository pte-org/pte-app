import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/reading_task_header_labels.dart';

void main() {
  group('readingTaskInstruction', () {
    const cases = {
      'MC_READING_SINGLE': AppStrings.readingInstructionMcSingle,
      'MC_READING_MULTIPLE': AppStrings.readingInstructionMcMultiple,
      'RE_ORDER_PARAGRAPHS': AppStrings.readingInstructionReorderParagraphs,
      'FILL_BLANKS_READING': AppStrings.readingInstructionFillBlanksDragDrop,
      'FILL_BLANKS_READING_WRITING': AppStrings.readingInstructionFillBlanksDropdown,
    };

    for (final entry in cases.entries) {
      test('maps ${entry.key} to its instruction text', () {
        expect(readingTaskInstruction(entry.key), entry.value);
      });
    }

    test('returns an empty string for an unrecognized task type', () {
      expect(readingTaskInstruction('WRITE_ESSAY'), '');
    });
  });
}
