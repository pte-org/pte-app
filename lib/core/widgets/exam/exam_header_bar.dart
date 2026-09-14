import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/constants/app_typography.dart';

/// Pure visual exam header. It deliberately knows nothing about a BLoC or API.
class ExamHeaderBar extends StatelessWidget {
  const ExamHeaderBar({
    super.key,
    required this.examTitle,
    required this.candidateName,
    required this.candidateId,
    required this.itemLabel,
    required this.timeLabel,
    this.timeContent,
    this.onAudioCheck,
    this.onForceSubmit,
  });

  final String examTitle;
  final String candidateName;
  final String candidateId;
  final String itemLabel;
  final String timeLabel;
  final Widget? timeContent;
  final VoidCallback? onAudioCheck;
  final VoidCallback? onForceSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.examHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth < AppDimensions.examHeaderCompactBreakpoint
            ? _compactRow()
            : _wideRow(),
      ),
    );
  }

  Widget _brand() {
    return Text(
      ExamChromeConfig.brandLabel,
      style: AppTypography.headlineMd.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingSm),
      child: SizedBox(
        height: 20,
        child: VerticalDivider(color: AppColors.divider),
      ),
    );
  }

  Widget _title({required bool flexible}) {
    final text = Text(
      examTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
    );
    return flexible ? Expanded(child: text) : text;
  }

  Widget _audioButton() {
    return IconButton(
      onPressed: onAudioCheck,
      tooltip: ExamChromeConfig.audioCheckTooltip,
      icon: const Icon(Icons.volume_up_outlined, size: 20),
      color: AppColors.textSecondary,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 36),
    );
  }

  Widget _submitButton() {
    return IconButton(
      onPressed: onForceSubmit,
      tooltip: ExamChromeConfig.submitExamTooltip,
      icon: const Icon(Icons.person_outline, size: 20),
      color: AppColors.primary,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 36),
    );
  }

  Widget _timer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.schedule_outlined,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        timeContent ??
            Text(
              timeLabel,
              key: const ValueKey('examAppBarCountdown'),
              style: AppTypography.timerTabular.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
      ],
    );
  }

  Widget _compactRow() {
    return Row(
      children: [
        _brand(),
        _divider(),
        _title(flexible: true),
        const SizedBox(width: AppDimensions.spacingSm),
        Flexible(
          child: Text(
            itemLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        _audioButton(),
        const SizedBox(width: AppDimensions.spacingSm),
        _timer(),
        const SizedBox(width: AppDimensions.spacingSm),
        _submitButton(),
      ],
    );
  }

  Widget _wideRow() {
    return Row(
      children: [
        _brand(),
        _divider(),
        _title(flexible: false),
        const Spacer(),
        Text(
          candidateName,
          style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Text(
          candidateId,
          style: AppTypography.labelMeta.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingLg),
        _audioButton(),
        const SizedBox(width: AppDimensions.spacingSm),
        Text(
          itemLabel,
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingLg),
        _timer(),
        const SizedBox(width: AppDimensions.spacingLg),
        _submitButton(),
      ],
    );
  }
}
