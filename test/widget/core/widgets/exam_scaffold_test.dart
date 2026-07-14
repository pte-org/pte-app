import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExamScaffold renders common exam chrome and toggles timer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExamScaffold(
          currentScreen: 3,
          totalScreens: 10,
          timeRemaining: const Duration(minutes: 42),
          onBack: () {},
          onFlag: () {},
          onNext: () {},
          body: const Text('Question content'),
        ),
      ),
    );

    // Minutes:seconds, ticking down each second (asserted before the first tick).
    expect(find.text('42:00'), findsOneWidget);
    expect(find.text(AppStrings.hideTime), findsOneWidget);
    expect(find.text(AppStrings.back), findsOneWidget);
    expect(find.text(AppStrings.flag), findsOneWidget);
    expect(find.text(AppStrings.next), findsOneWidget);
    expect(find.text('Question content'), findsOneWidget);

    await tester.tap(find.text(AppStrings.hideTime));
    await tester.pump();

    expect(find.text('42:00'), findsNothing);
    expect(find.text(AppStrings.showTime), findsOneWidget);
  });
}
