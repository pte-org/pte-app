import 'package:flutter_test/flutter_test.dart';

import 'package:aptis_app/app.dart';

void main() {
  testWidgets('AptisApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const AptisApp());
    expect(find.text('Aptis'), findsOneWidget);
  });
}
