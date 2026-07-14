import 'package:aptis_app/core/widgets/resizable/resizable_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _desktopTestSurfaceSize = Size(1400, 900);
const double _defaultBoxWidth = 600;
const double _defaultBoxHeight = 300;
const double _minBoxWidth = 300;
const double _minBoxHeight = 160;
const double _maxBoxWidth = 1000;
const double _maxBoxHeight = 700;
const Offset _resizeDragOffset = Offset(120, 80);
const Key _resizableChildKey = Key('resizable-child');

void main() {
  testWidgets('ResizableBox grows in both dimensions from the corner handle', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = _desktopTestSurfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResizableBox(
            defaultWidth: _defaultBoxWidth,
            defaultHeight: _defaultBoxHeight,
            minWidth: _minBoxWidth,
            minHeight: _minBoxHeight,
            maxWidth: _maxBoxWidth,
            maxHeight: _maxBoxHeight,
            child: ColoredBox(key: _resizableChildKey, color: Colors.white),
          ),
        ),
      ),
    );

    final initialSize = tester.getSize(find.byKey(_resizableChildKey));

    await tester.drag(find.byIcon(Icons.open_in_full), _resizeDragOffset);
    await tester.pump();

    final resizedSize = tester.getSize(find.byKey(_resizableChildKey));
    expect(resizedSize.width, greaterThan(initialSize.width));
    expect(resizedSize.height, greaterThan(initialSize.height));
  });
}
