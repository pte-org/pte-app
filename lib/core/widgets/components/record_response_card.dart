import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/components/pte_audio_panel.dart';

/// Offline-safe presentation of the PTE recorded-answer surface.
///
/// It intentionally renders a preparation state only. Recording, microphone
/// access and upload transitions remain feature-owned and are injected by the
/// runtime screens; the design preview must never create those side effects.
class RecordResponseCard extends StatelessWidget {
  const RecordResponseCard({
    super.key,
    required this.prepSeconds,
    required this.responseSeconds,
  });

  final int prepSeconds;
  final int responseSeconds;

  @override
  Widget build(BuildContext context) {
    return PteAudioPanel(
      variant: PteAudioPanelVariant.recorder,
      statusLabel:
          '${AppStrings.audioBeginningInPrefix}$prepSeconds${AppStrings.audioSecondsSuffix}',
      progress: 0.0,
      timeLabel:
          '0:00${AppStrings.audioTimeSeparator}${formatPteAudioDuration(Duration(seconds: responseSeconds))}',
    );
  }
}
