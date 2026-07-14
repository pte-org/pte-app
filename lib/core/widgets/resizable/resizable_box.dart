import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';

class ResizableBox extends StatefulWidget {
  final double defaultWidth;
  final double defaultHeight;
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;
  final double paddingSides;
  final double viewportPadding;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const ResizableBox({
    super.key,
    required this.defaultWidth,
    required this.defaultHeight,
    required this.minWidth,
    required this.minHeight,
    required this.maxWidth,
    required this.maxHeight,
    required this.child,
    this.viewportPadding = AppDimensions.spacingXl,
    this.paddingSides = AppDimensions.resizablePaddingSides,
    this.padding = const EdgeInsets.all(AppDimensions.spacingXl),
  });

  @override
  State<ResizableBox> createState() => _ResizableBoxState();
}

class _ResizableBoxState extends State<ResizableBox> {
  double? _width;
  double? _height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = _resolveWidth(constraints.maxWidth);
        final boxHeight = _resolveHeight(constraints.maxHeight);

        return Center(
          child: Padding(
            padding: widget.padding,
            child: SizedBox(
              width: boxWidth,
              height: boxHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: widget.child),
                  Positioned(
                    right: AppDimensions.resizableHandleInset,
                    bottom: AppDimensions.resizableHandleInset,
                    child: _ResizeHandle(
                      onDrag: (delta) => _resize(
                        delta,
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _resolveWidth(double viewportWidth) {
    final maxWidth = _maxWidthForViewport(viewportWidth);
    return (_width ?? widget.defaultWidth)
        .clamp(widget.minWidth, maxWidth)
        .toDouble();
  }

  double _resolveHeight(double viewportHeight) {
    final maxHeight = _maxHeightForViewport(viewportHeight);
    return (_height ?? widget.defaultHeight)
        .clamp(widget.minHeight, maxHeight)
        .toDouble();
  }

  double _maxWidthForViewport(double viewportWidth) {
    final availableWidth =
        viewportWidth - widget.viewportPadding * widget.paddingSides;

    return availableWidth.clamp(widget.minWidth, widget.maxWidth).toDouble();
  }

  double _maxHeightForViewport(double viewportHeight) {
    final availableHeight =
        viewportHeight - widget.viewportPadding * widget.paddingSides;

    return availableHeight.clamp(widget.minHeight, widget.maxHeight).toDouble();
  }

  void _resize(Offset delta, double viewportWidth, double viewportHeight) {
    final currentWidth = _resolveWidth(viewportWidth);
    final currentHeight = _resolveHeight(viewportHeight);
    final maxWidth = _maxWidthForViewport(viewportWidth);
    final maxHeight = _maxHeightForViewport(viewportHeight);

    setState(() {
      _width = (currentWidth + delta.dx)
          .clamp(widget.minWidth, maxWidth)
          .toDouble();
      _height = (currentHeight + delta.dy)
          .clamp(widget.minHeight, maxHeight)
          .toDouble();
    });
  }
}

class _ResizeHandle extends StatelessWidget {
  final ValueChanged<Offset> onDrag;

  const _ResizeHandle({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: const SizedBox.square(
          dimension: AppDimensions.resizableHandleSize,
          child: Icon(
            Icons.open_in_full,
            color: AppColors.textMedium,
            size: AppDimensions.bottomBarChevronSize,
          ),
        ),
      ),
    );
  }
}
