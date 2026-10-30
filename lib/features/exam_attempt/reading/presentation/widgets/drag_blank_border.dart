import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';

class DragBlankBorder extends CustomPainter {
  const DragBlankBorder({this.highlighted = false});
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = highlighted ? AppColors.brandPrimary : AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      );
    for (final metric in path.computeMetrics()) {
      for (var offset = 0.0; offset < metric.length; offset += 8) {
        canvas.drawPath(metric.extractPath(offset, offset + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DragBlankBorder oldDelegate) =>
      oldDelegate.highlighted != highlighted;
}
