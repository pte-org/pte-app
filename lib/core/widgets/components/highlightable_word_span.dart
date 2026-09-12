import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_typography.dart';

class HighlightableWordSpan extends StatelessWidget {
  const HighlightableWordSpan({
    super.key,
    required this.word,
    this.highlighted = false,
    this.onTap,
  });

  final String word;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: highlighted,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Text(
          word,
          style: AppTypography.bodyPassage.copyWith(
            color: AppColors.textPrimary,
            backgroundColor: highlighted
                ? AppColors.interactiveHighlight
                : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
