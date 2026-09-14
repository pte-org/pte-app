import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recorded Answer',
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _Badge(label: 'Preparation'),
            ],
          ),
          const Divider(height: AppDimensions.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current status:',
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Flexible(
                child: Text(
                  'Beginning in $prepSeconds seconds',
                  textAlign: TextAlign.end,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          const LinearProgressIndicator(
            value: 0.08,
            minHeight: AppDimensions.recordingProgressBarHeight,
            backgroundColor: AppColors.surfaceContainerHighest,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingSm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.border),
              ),
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Audio Input Level',
                        style: AppTypography.labelMeta.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Flexible(
                      child: Text(
                        'Standby',
                        textAlign: TextAlign.end,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Row(
                  children: [
                    for (var index = 0; index < 12; index++)
                      Expanded(
                        child: Container(
                          height: 10,
                          margin: EdgeInsets.only(
                            right: index == 11 ? 0 : AppDimensions.spacingXs,
                          ),
                          color: index < 3
                              ? AppColors.surfaceContainerHighest
                              : AppColors.borderSubtle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: _TimeBox(label: 'Prep time', seconds: prepSeconds),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: _TimeBox(label: 'Record time', seconds: responseSeconds),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm,
        vertical: AppDimensions.spacingXs,
      ),
      color: AppColors.primary,
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.seconds});

  final String label;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingSm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '$seconds seconds',
            textAlign: TextAlign.center,
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
