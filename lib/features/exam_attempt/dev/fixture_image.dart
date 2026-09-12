import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_typography.dart';

class PreviewFixtureImage extends StatelessWidget {
  const PreviewFixtureImage({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: CustomPaint(
          painter: _FixtureImagePainter(),
          child: Center(
            child: Text(
              'Offline image fixture',
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FixtureImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.previewSky);
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .22),
      size.shortestSide * .1,
      Paint()..color = AppColors.previewSun,
    );
    final ground = Path()
      ..moveTo(0, size.height * .62)
      ..quadraticBezierTo(
        size.width * .3,
        size.height * .42,
        size.width * .55,
        size.height * .63,
      )
      ..quadraticBezierTo(
        size.width * .82,
        size.height * .4,
        size.width,
        size.height * .58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, Paint()..color = AppColors.previewGround);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
