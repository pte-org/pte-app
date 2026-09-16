import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/report/domain/report_response.dart';

void main() {
  group('SkillScoreResponse.fromJson', () {
    test('parses a sufficient-data entry with a numeric score', () {
      final skill = SkillScoreResponse.fromJson({'skill': 'Reading', 'score': 75, 'sufficientData': true});

      expect(skill.skill, 'Reading');
      expect(skill.score, 75);
      expect(skill.sufficientData, isTrue);
    });

    test('parses an insufficient-data entry with a null score', () {
      final skill = SkillScoreResponse.fromJson({'skill': 'Speaking', 'score': null, 'sufficientData': false});

      expect(skill.score, isNull);
      expect(skill.sufficientData, isFalse);
    });

    test('parses the edge case: a non-null score alongside sufficientData:false', () {
      final skill = SkillScoreResponse.fromJson({'skill': 'Writing', 'score': 42, 'sufficientData': false});

      expect(skill.score, 42);
      expect(skill.sufficientData, isFalse);
    });
  });

  group('ReportResponse.fromJson', () {
    Map<String, dynamic> skillJson(String skill, {int? score, bool sufficientData = true}) =>
        {'skill': skill, 'score': score, 'sufficientData': sufficientData};

    test('parses the full field set including nested skill list and publishedAt (no separate enabling-skills list since Phase 5)', () {
      final report = ReportResponse.fromJson({
        'attemptPublicId': 'attempt-1',
        'sessionPublicId': 'session-1',
        'published': true,
        'publishedAt': '2026-07-20T10:00:00.000Z',
        'overall': skillJson('Overall', score: 65),
        'communicativeSkills': [skillJson('Reading', score: 70), skillJson('Speaking', score: null, sufficientData: false)],
      });

      expect(report.attemptPublicId, 'attempt-1');
      expect(report.sessionPublicId, 'session-1');
      expect(report.published, isTrue);
      expect(report.publishedAt, DateTime.parse('2026-07-20T10:00:00.000Z'));
      expect(report.overall, isNotNull);
      expect(report.overall!.score, 65);
      expect(report.communicativeSkills, hasLength(2));
      expect(report.communicativeSkills[1].sufficientData, isFalse);
    });

    test('parses a null publishedAt without throwing', () {
      final report = ReportResponse.fromJson({
        'attemptPublicId': 'attempt-1',
        'sessionPublicId': 'session-1',
        'published': false,
        'publishedAt': null,
        'overall': skillJson('Overall', score: null, sufficientData: false),
        'communicativeSkills': <dynamic>[],
      });

      expect(report.publishedAt, isNull);
      expect(report.communicativeSkills, isEmpty);
    });

    test('parses a null overall (FR-20: exam did not cover all 4 skills) without throwing', () {
      final report = ReportResponse.fromJson({
        'attemptPublicId': 'attempt-1',
        'sessionPublicId': 'session-1',
        'published': true,
        'publishedAt': null,
        'overall': null,
        'communicativeSkills': [skillJson('Reading', score: 70), skillJson('Speaking', score: 80)],
      });

      expect(report.overall, isNull);
      expect(report.communicativeSkills, hasLength(2));
    });

    test('a present overall with sufficientData:false is NOT the same as a null overall', () {
      final report = ReportResponse.fromJson({
        'attemptPublicId': 'attempt-1',
        'sessionPublicId': 'session-1',
        'published': true,
        'publishedAt': null,
        'overall': skillJson('Overall', score: null, sufficientData: false),
        'communicativeSkills': <dynamic>[],
      });

      expect(report.overall, isNotNull);
      expect(report.overall!.sufficientData, isFalse);
    });
  });
}
