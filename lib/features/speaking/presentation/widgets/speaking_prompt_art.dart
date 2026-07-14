import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';

const double _sunCenterXFactor = 0.74;
const double _sunCenterYFactor = 0.32;
const double _sunRadiusFactor = 0.12;
const double _cloudCenterXFactor = 0.46;
const double _cloudCenterYFactor = 0.28;
const double _cloudRadiusFactor = 0.15;
const double _mountainPeakYFactor = 0.42;
const double _fieldStartYFactor = 0.62;
const double _groundStartYFactor = 0.78;
const double _treeTrunkXFactor = 0.38;
const double _treeTopYFactor = 0.5;

class SpeakingPromptArt extends StatelessWidget {
  final double? width;
  final double? height;

  const SpeakingPromptArt({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.speakingSampleImageLabel,
      image: true,
      child: Container(
        width: width ?? AppDimensions.speakingPromptImageWidth,
        height: height ?? AppDimensions.speakingPromptImageHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.backgroundWhite,
            width: AppDimensions.speakingPromptImageBorderWidth,
          ),
        ),
        child: CustomPaint(painter: _SpeakingPromptArtPainter()),
      ),
    );
  }
}

class _SpeakingPromptArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.speakingImageSky,
    );
    _paintSun(canvas, size);
    _paintCloud(canvas, size);
    _paintMountains(canvas, size);
    _paintField(canvas, size);
    _paintTree(canvas, size);
  }

  void _paintSun(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * _sunCenterXFactor, size.height * _sunCenterYFactor),
      size.shortestSide * _sunRadiusFactor,
      Paint()..color = AppColors.speakingImageCloud,
    );
  }

  void _paintCloud(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(
        size.width * _cloudCenterXFactor,
        size.height * _cloudCenterYFactor,
      ),
      size.shortestSide * _cloudRadiusFactor,
      Paint()..color = AppColors.speakingImageCloud,
    );
  }

  void _paintMountains(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * _fieldStartYFactor)
      ..lineTo(
        size.width * _cloudCenterXFactor,
        size.height * _mountainPeakYFactor,
      )
      ..lineTo(size.width, size.height * _fieldStartYFactor)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.speakingImageMountain);
  }

  void _paintField(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * _fieldStartYFactor,
        size.width,
        size.height * (_groundStartYFactor - _fieldStartYFactor),
      ),
      Paint()..color = AppColors.speakingImageField,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * _groundStartYFactor,
        size.width,
        size.height * (1 - _groundStartYFactor),
      ),
      Paint()..color = AppColors.speakingImageGround,
    );
  }

  void _paintTree(Canvas canvas, Size size) {
    final trunkPaint = Paint()..color = AppColors.textMedium;
    canvas.drawLine(
      Offset(size.width * _treeTrunkXFactor, size.height * _fieldStartYFactor),
      Offset(size.width * _treeTrunkXFactor, size.height * _groundStartYFactor),
      trunkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * _treeTrunkXFactor, size.height * _treeTopYFactor),
      AppDimensions.speakingDotSize,
      Paint()..color = AppColors.textDark,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeakingPromptArtPainter oldDelegate) => false;
}
