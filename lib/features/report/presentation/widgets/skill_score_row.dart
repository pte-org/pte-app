import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/features/report/domain/report_response.dart';
import 'package:pte_app/features/report/constants/report_strings.dart';

/// Shared by both the Overall row and every `communicativeSkills` entry
/// (phase-08 Design Constraints) — one implementation, not several
/// near-duplicates. `sufficientData` is checked directly, never `score`'s
/// nullness, and a present `score` alongside `sufficientData: false` still
/// renders "insufficient data" (phase-08 Design Constraints, Step 9's
/// edge case). The two outcomes are structurally distinct widgets — a
/// [Text] with a distinct color/style, not the same widget with different
/// text — so a quick-scanning student can't mistake one for the other.
class SkillScoreRow extends StatelessWidget {
  const SkillScoreRow({super.key, required this.skillScore});

  final SkillScoreResponse skillScore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMedium / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(skillScore.skill),
          if (!skillScore.sufficientData)
            const Text(
              ReportStrings.reportInsufficientDataLabel,
              style: TextStyle(color: AppColors.textPrimary, fontStyle: FontStyle.italic),
            )
          else
            Text('${skillScore.score}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
