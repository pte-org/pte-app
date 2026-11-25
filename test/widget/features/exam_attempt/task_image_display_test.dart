import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:pte_app/features/exam_attempt/data/attempt_audio_cache.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/task_image_display.dart';

class _OkAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(Uint8List.fromList([1, 2, 3, 4]), 200);
  }
}

void main() {
  const imageUrl = 'https://picsum.photos/seed/describe-image-fixture/800/600';

  Widget buildSubject() {
    return const MaterialApp(
      home: Scaffold(body: TaskImageDisplay(imageUrl: imageUrl)),
    );
  }

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets(
    'builds an Image widget backed by a NetworkImage for the given imageUrl',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<NetworkImage>());
      expect((imageWidget.image as NetworkImage).url, imageUrl);
    },
  );

  testWidgets(
    'renders inside a bounded SizedBox height, no unbounded-constraint layout error',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      // Pumping without a real network round-trip already exercises layout —
      // if the height were unbounded this would throw during pumpWidget.
      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(of: find.byType(Image), matching: find.byType(SizedBox))
            .first,
      );
      expect(sizedBox.height, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows the downloaded copy instead of the network once the image is cached',
    (tester) async {
      final root = await tester.runAsync(
        () => Directory.systemTemp.createTemp('task_image_display_test'),
      );
      final cache = AttemptAudioCache(
        dio: Dio()..httpClientAdapter = _OkAdapter(),
        rootProvider: () async => Directory('${root!.path}/cache'),
      );
      await tester.runAsync(() => cache.prefetch([imageUrl]));
      GetIt.instance.registerSingleton<AttemptAudioCache>(cache);

      await tester.pumpWidget(buildSubject());

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<FileImage>());
      await tester.runAsync(() => root!.delete(recursive: true));
    },
  );
}
