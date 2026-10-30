import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/widgets/components/pte_volume_button.dart';

void main() {
  testWidgets(
    'volume applies immediately and mute restores the last audible level',
    (tester) async {
      final volume = VolumeService()..value = 0.75;
      addTearDown(volume.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: PteVolumeButton(volumeService: volume),
            ),
          ),
        ),
      );
      expect(find.byType(Slider), findsNothing);
      await tester.tap(find.byTooltip('Volume'));
      await tester.pumpAndSettle();
      expect(find.text('75%'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('OK'), findsNothing);
      await tester.tap(find.byTooltip('Mute'));
      await tester.pump();
      expect(volume.value, 0);
      expect(find.text('0%'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 0);
      await tester.tap(find.byTooltip('Unmute'));
      await tester.pump();
      expect(volume.value, 0.75);
      final slider = find.byType(Slider);
      await tester.tapAt(tester.getCenter(slider));
      await tester.pumpAndSettle();
      expect(volume.value, closeTo(0.5, 0.05));
      final updated = volume.value;
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(slider, findsNothing);
      await tester.tap(find.byTooltip('Volume'));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(slider).value, updated);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(slider, findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final width in [375.0, 1080.0]) {
    testWidgets(
      'popup stays compact inside a $width wide screen near an edge',
      (tester) async {
        tester.view.physicalSize = Size(width, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final volume = VolumeService();
        addTearDown(volume.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: PteVolumeButton(volumeService: volume),
              ),
            ),
          ),
        );
        await tester.tap(find.byTooltip('Volume'));
        await tester.pumpAndSettle();
        final rect = tester.getRect(find.byType(Slider));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
        expect(rect.bottom, lessThanOrEqualTo(600));
        expect(rect.height, lessThanOrEqualTo(48));
        final popup = tester.getRect(find.byType(Column));
        expect(popup.height, lessThan(120));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
