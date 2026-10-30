import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';

/// One fixed-width column of green segments, filled from bottom to top.
/// [level] is normalized to 0..1; silence leaves the column empty.
class PteAudioLevelMeter extends StatelessWidget {
  const PteAudioLevelMeter({super.key, required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final normalized = level.isFinite ? level.clamp(0.0, 1.0) : 0.0;
    final litCount = (normalized * AppDimensions.audioPanelMeterSegments)
        .ceil();
    return SizedBox(
      width: AppDimensions.audioPanelMeterWidth,
      height: AppDimensions.audioPanelMeterHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var index = 0; index < litCount; index++)
            Padding(
              padding: const EdgeInsets.only(
                top: AppDimensions.audioPanelMeterSegmentGap,
              ),
              child: const SizedBox(
                width: double.infinity,
                height: AppDimensions.audioPanelMeterSegmentHeight,
                child: ColoredBox(color: AppColors.audioPanelMeter),
              ),
            ),
        ],
      ),
    );
  }
}
