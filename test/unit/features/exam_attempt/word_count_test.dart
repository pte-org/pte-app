import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/domain/word_count.dart';

void main() {
  group('countWords — pure function, no widget pump needed (Step 11)', () {
    test('empty string counts as 0', () {
      expect(countWords(''), 0);
    });

    test('whitespace-only string counts as 0, not 1', () {
      expect(countWords('   \t\n  '), 0);
    });

    test('a single word counts as 1', () {
      expect(countWords('hello'), 1);
    });

    test('multiple spaces between words do not inflate the count', () {
      expect(countWords('hello    world'), 2);
    });

    test('leading and trailing whitespace is ignored', () {
      expect(countWords('   hello world   '), 2);
    });

    test('tabs and newlines count as word separators', () {
      expect(countWords('hello\tworld\nfoo'), 3);
    });

    test('a normal multi-word sentence counts every word', () {
      expect(countWords('the quick brown fox jumps'), 5);
    });
  });
}
