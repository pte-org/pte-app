/// One skill's score within a [ReportResponse]. `sufficientData` is the
/// authoritative signal for "insufficient data," not `score`'s nullness —
/// the two could in principle disagree, and a present `score` alongside
/// `sufficientData: false` must still render as insufficient (phase-08
/// Design Constraints).
class SkillScoreResponse {
  const SkillScoreResponse({required this.skill, required this.score, required this.sufficientData});

  final String skill;
  final int? score;
  final bool sufficientData;

  factory SkillScoreResponse.fromJson(Map<String, dynamic> json) {
    return SkillScoreResponse(
      skill: json['skill'] as String,
      score: json['score'] as int?,
      sufficientData: json['sufficientData'] as bool,
    );
  }
}

/// A successfully-fetched (200) report. Reaching this shape at all already
/// implies the report is visible to this student — `published`/
/// `publishedAt` are informational display fields only, not a second
/// not-published check (phase-08 Design Constraints).
///
/// Since Phase 5 (plans/score-template-exam-generation): no more separate
/// enabling-skills list on the wire (spec Out of Scope — the pinned
/// ScoreTemplate has no weight column for them). `overall` is `null` when the exam
/// didn't cover all 4 skills (FR-20 — "not applicable"), distinct from a
/// present [SkillScoreResponse] with `sufficientData: false` ("not enough
/// data yet"). `communicativeSkills` only ever contains skills that were
/// actually tested (FR-19).
class ReportResponse {
  const ReportResponse({
    required this.attemptPublicId,
    required this.sessionPublicId,
    required this.published,
    required this.publishedAt,
    required this.overall,
    required this.communicativeSkills,
  });

  final String attemptPublicId;
  final String sessionPublicId;
  final bool published;
  final DateTime? publishedAt;
  final SkillScoreResponse? overall;
  final List<SkillScoreResponse> communicativeSkills;

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      attemptPublicId: json['attemptPublicId'] as String,
      sessionPublicId: json['sessionPublicId'] as String,
      published: json['published'] as bool,
      publishedAt: json['publishedAt'] == null ? null : DateTime.parse(json['publishedAt'] as String),
      overall: json['overall'] == null ? null : SkillScoreResponse.fromJson(json['overall'] as Map<String, dynamic>),
      communicativeSkills: (json['communicativeSkills'] as List<dynamic>)
          .map((skill) => SkillScoreResponse.fromJson(skill as Map<String, dynamic>))
          .toList(),
    );
  }
}
