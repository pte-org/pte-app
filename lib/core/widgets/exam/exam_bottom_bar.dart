import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

class ExamBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onFlag;
  final VoidCallback onNext;

  /// Whether the leading Back button is shown. The first screen of a part has
  /// no Back action, so callers can hide it while keeping Flag/Next aligned.
  final bool showBack;

  const ExamBottomBar({
    super.key,
    required this.onBack,
    required this.onFlag,
    required this.onNext,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.bottomBarHeight,
      decoration: const BoxDecoration(color: AppColors.bottomBarSpacer),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBack) ...[
            _BottomBarButton(
              label: AppStrings.back,
              backgroundColor: AppColors.bottomBarButtonBackground,
              onTap: onBack,
              icon: const Icon(
                Icons.chevron_left,
                size: AppDimensions.bottomBarChevronSize,
                color: AppColors.textDark,
              ),
              iconBefore: true,
            ),
            const _VerticalDivider(),
          ],
          const Expanded(child: SizedBox.shrink()),
          const _VerticalDivider(),
          _BottomBarButton(
            label: AppStrings.flag,
            backgroundColor: AppColors.bottomBarFlagBackground,
            onTap: onFlag,
            icon: CustomPaint(
              size: const Size(
                AppDimensions.flagIconSize,
                AppDimensions.flagIconSize,
              ),
              painter: _FlagPainter(color: AppColors.bottomBarButtonBackground),
            ),
            iconBefore: false,
          ),
          const _VerticalDivider(),
          _BottomBarButton(
            label: AppStrings.next,
            backgroundColor: AppColors.bottomBarButtonBackground,
            onTap: onNext,
            icon: const Icon(
              Icons.chevron_right,
              size: AppDimensions.bottomBarChevronSize,
              color: AppColors.textDark,
            ),
            iconBefore: false,
          ),
        ],
      ),
    );
  }
}

/// 1px vertical separator between bottom-bar segments.
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.borderWidthThin,
      color: AppColors.dividerGray,
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;
  final Widget? icon;
  final bool iconBefore;

  const _BottomBarButton({
    required this.label,
    required this.backgroundColor,
    required this.onTap,
    this.icon,
    required this.iconBefore,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.bottomBarButtonWidth,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && iconBefore) ...[
                icon!,
                const SizedBox(
                  width: AppDimensions.bottomBarButtonIconGapLeading,
                ),
              ],
              Text(label, style: AppTextStyles.navButton),
              if (icon != null && !iconBefore) ...[
                const SizedBox(
                  width: AppDimensions.bottomBarButtonIconGapTrailing,
                ),
                icon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final Color color;

  _FlagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Flagpole
    canvas.drawLine(
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.15, size.height),
      Paint()
        ..color = color
        ..strokeWidth = AppDimensions.flagStrokeWidth,
    );

    // Flag banner
    final flagPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.1)
      ..lineTo(size.width * 0.85, size.height * 0.3)
      ..lineTo(size.width * 0.15, size.height * 0.5)
      ..close();

    canvas.drawPath(flagPath, paint);
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      color != oldDelegate.color;
}
