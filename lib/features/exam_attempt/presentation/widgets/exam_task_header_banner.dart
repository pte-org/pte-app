import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/widgets/components/subheader_banner.dart';

/// Compatibility façade for existing pages while the task-header registry is
/// migrated. The rendered component is the design-system sub-header, with no
/// gradient or decorative star.
class ExamTaskHeaderBanner extends StatelessWidget {
  const ExamTaskHeaderBanner({
    super.key,
    required this.title,
    this.instruction,
  });

  final String title;
  final String? instruction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMedium,
        AppDimensions.spacingMedium,
        AppDimensions.spacingMedium,
        0,
      ),
      child: SubheaderBanner(title: title, subtitle: instruction),
    );
  }
}
