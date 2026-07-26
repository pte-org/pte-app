import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'brand_logo.dart';

const int _timerSegmentDigits = 2;
const int _secondsPerMinute = 60;
const String _timerPadDigit = '0';
const String _timerSeparator = ':';

class ExamAppBar extends StatelessWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final bool showTimer;
  final VoidCallback onToggleTimer;

  const ExamAppBar({
    super.key,
    required this.currentScreen,
    required this.totalScreens,
    required this.timeRemaining,
    required this.showTimer,
    required this.onToggleTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.topBarBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.topBarPaddingHorizontal,
              vertical: AppDimensions.topBarPaddingVertical,
            ),
            child: Row(
              children: [
                _buildZoomIcon(),
                const SizedBox(width: AppDimensions.topBarGap),
                Container(
                  width: AppDimensions.borderWidthThin,
                  height: AppDimensions.topBarDividerHeight,
                  color: AppColors.topBarBorder,
                ),
                const SizedBox(width: AppDimensions.topBarGap),
                if (showTimer) ...[
                  _buildTimerBox(),
                  const SizedBox(width: AppDimensions.topBarGap),
                  _buildTimeToggleButton(isTimerVisible: true),
                ] else ...[
                  _buildTimeToggleButton(isTimerVisible: false),
                ],
                const Spacer(),
                _buildLogo(),
                const Spacer(),
                _buildScreenCounter(),
                const SizedBox(width: AppDimensions.topBarScreenGap),
                _buildMenuIcon(),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: AppDimensions.topBarAccentHeight,
            color: AppColors.accentRed,
          ),
        ],
      ),
    );
  }

  Widget _buildZoomIcon() {
    return const Icon(
      Icons.zoom_in,
      color: AppColors.textDark,
      size: AppDimensions.topBarZoomIconSize,
    );
  }

  Widget _buildTimerBox() {
    final minutes = timeRemaining.inMinutes.toString().padLeft(
      _timerSegmentDigits,
      _timerPadDigit,
    );
    final seconds = (timeRemaining.inSeconds % _secondsPerMinute)
        .toString()
        .padLeft(_timerSegmentDigits, _timerPadDigit);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$minutes$_timerSeparator$seconds',
          style: AppTextStyles.timerValue,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.timerMins, style: AppTextStyles.timerLabel),
            const SizedBox(width: AppDimensions.timerLabelGap),
            Text(AppStrings.timerSecs, style: AppTextStyles.timerLabel),
          ],
        ),
      ],
    );
  }

  /// Circular toggle button. The label depends on whether the timer is
  /// currently visible.
  Widget _buildTimeToggleButton({required bool isTimerVisible}) {
    return GestureDetector(
      onTap: onToggleTimer,
      child: Container(
        width: AppDimensions.timeToggleSize,
        height: AppDimensions.timeToggleSize,
        decoration: const BoxDecoration(
          color: AppColors.bottomBarBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          isTimerVisible ? AppStrings.hideTime : AppStrings.showTime,
          textAlign: TextAlign.center,
          style: AppTextStyles.timeToggle,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const BrandLogo();
  }

  Widget _buildScreenCounter() {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.screenCounterLabel,
        children: [
          const TextSpan(text: AppStrings.screenLabel),
          TextSpan(
            text: '$currentScreen',
            style: AppTextStyles.screenCounterNumber,
          ),
          const TextSpan(text: AppStrings.screenOf),
          TextSpan(
            text: '$totalScreens',
            style: AppTextStyles.screenCounterNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (_) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (_) => Container(
              width: AppDimensions.dotSize,
              height: AppDimensions.dotSize,
              margin: const EdgeInsets.all(AppDimensions.dotMargin),
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
