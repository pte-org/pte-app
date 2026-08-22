import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';

void main() {
  group('parseBlankPrompt', () {
    test('no markers returns a single text segment', () {
      final segments = parseBlankPrompt('Just a plain sentence.');

      expect(segments, hasLength(1));
      expect(segments.single, isA<PromptTextSegment>());
      expect((segments.single as PromptTextSegment).text, 'Just a plain sentence.');
    });

    test('single marker splits into text-gap-text', () {
      final segments = parseBlankPrompt('Before {{0}} after.');

      expect(segments, hasLength(3));
      expect((segments[0] as PromptTextSegment).text, 'Before ');
      expect((segments[1] as PromptGapSegment).gapIndex, 0);
      expect((segments[2] as PromptTextSegment).text, ' after.');
    });

    test('multiple markers preserve gap order and index', () {
      final segments = parseBlankPrompt('A {{0}} B {{1}} C');

      final gapIndexes = segments.whereType<PromptGapSegment>().map((s) => s.gapIndex).toList();
      expect(gapIndexes, [0, 1]);
      expect(segments, hasLength(5));
    });

    test('marker at the very start of the string', () {
      final segments = parseBlankPrompt('{{0}} starts here');

      expect(segments.first, isA<PromptGapSegment>());
      expect((segments.first as PromptGapSegment).gapIndex, 0);
    });

    test('marker at the very end of the string', () {
      final segments = parseBlankPrompt('ends with {{0}}');

      expect(segments.last, isA<PromptGapSegment>());
      expect((segments.last as PromptGapSegment).gapIndex, 0);
    });

    test('string that is only a marker, no surrounding text', () {
      final segments = parseBlankPrompt('{{0}}');

      expect(segments, hasLength(1));
      expect(segments.single, isA<PromptGapSegment>());
    });

    test('malformed marker (non-digit inside braces) degrades to literal text, never throws', () {
      expect(() => parseBlankPrompt('bad {{abc}} marker'), returnsNormally);
      final segments = parseBlankPrompt('bad {{abc}} marker');

      expect(segments.whereType<PromptGapSegment>(), isEmpty);
      expect(segments, hasLength(1));
      expect((segments.single as PromptTextSegment).text, 'bad {{abc}} marker');
    });

    test('empty string returns a single empty text segment', () {
      final segments = parseBlankPrompt('');

      expect(segments, hasLength(1));
      expect((segments.single as PromptTextSegment).text, '');
    });
  });
}
