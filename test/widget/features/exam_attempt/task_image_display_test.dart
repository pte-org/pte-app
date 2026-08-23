import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/task_image_display.dart';

void main() {
  const imageUrl = 'https://picsum.photos/seed/describe-image-fixture/800/600';

  Widget buildSubject() {
    return const MaterialApp(home: Scaffold(body: TaskImageDisplay(imageUrl: imageUrl)));
  }

  testWidgets('builds an Image widget backed by a NetworkImage for the given imageUrl', (tester) async {
    await tester.pumpWidget(buildSubject());

    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.image, isA<NetworkImage>());
    expect((imageWidget.image as NetworkImage).url, imageUrl);
  });

  testWidgets('renders inside a bounded SizedBox height, no unbounded-constraint layout error', (tester) async {
    await tester.pumpWidget(buildSubject());

    // Pumping without a real network round-trip already exercises layout —
    // if the height were unbounded this would throw during pumpWidget.
    final sizedBox = tester.widget<SizedBox>(
      find.ancestor(of: find.byType(Image), matching: find.byType(SizedBox)).first,
    );
    expect(sizedBox.height, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
