import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Wraps a reading task's question content in a white "paper" card floating
/// over the light-grey page background set by each reading screen — purely
/// visual, gives the content region a defined edge instead of sitting flush
/// against the scaffold. Reading-only by construction (only the 5 reading
/// screens use it); Speaking/Writing screens are untouched.
///
/// The background color is painted by a [Material] (not a `Container`'s
/// `BoxDecoration.color`) — some reading content (`RadioListTile` in the MC
/// screens) needs a `Material` ancestor for its ink splashes, and a colored
/// `DecoratedBox` between it and that ancestor trips Flutter's "ListTile
/// background color or ink splashes may be invisible" assertion.
class ReadingContentCard extends StatelessWidget {
  const ReadingContentCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.readingContentCardRadius);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.readingContentCardMargin),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [BoxShadow(color: AppColors.readingContentCardShadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Material(
          color: AppColors.onPrimary,
          clipBehavior: Clip.antiAlias,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: AppColors.readingContentCardBorder)),
            child: child,
          ),
        ),
      ),
    );
  }
}
