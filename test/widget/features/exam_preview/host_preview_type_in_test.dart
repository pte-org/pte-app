import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart';

PreviewItem _item(int offset) => PreviewItem(
  orderIndex: 0,
  snapshotItemPublicId: 'i',
  sourceQuestionPublicId: 'q',
  section: 'LISTENING',
  taskType: 'FILL_IN_THE_BLANKS_TYPE_IN',
  taskTypeCode: 'FILL_IN_THE_BLANKS_TYPE_IN',
  taskTypeDisplayName: null,
  title: null,
  promptText: 'The {{$offset}} example has {{${offset + 1}}} answers.',
  audioUrl: 'https://media.test/audio.wav',
  imageUrl: null,
  minWordCount: null,
  maxWordCount: null,
  options: [],
  runtime: null,
  runtimeMappingVersion: null,
  runtimeMappingStatus: null,
  prepSeconds: 0,
  responseSeconds: 60,
  preListenSeconds: null,
  preRecordSeconds: null,
  audioDurationSeconds: 30,
  audioUrlExpiresAt: null,
  imageUrlExpiresAt: null,
);

void main() {
  for (final width in [375.0, 1280.0]) {
    for (final offset in [0, 1]) {
      testWidgets(
        'Type In has audio above inline inputs at $width with marker base $offset',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          Object? answer = <int, String>{0: 'saved'};
          late StateSetter refresh;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    refresh = setState;
                    return HostPreviewTaskDispatcher(
                      model: PreviewTaskUiAdapter.adapt(_item(offset)),
                      answer: answer,
                      onAnswerChanged: (next) => setState(() => answer = next),
                    );
                  },
                ),
              ),
            ),
          );
          final passage = find.byKey(const ValueKey('typeInPassage'));
          final audio = find.byKey(const ValueKey('pteAudioPanel'));
          final fields = find.byType(TextField);
          expect(find.text('Fill in the Blanks (Type In)'), findsOneWidget);
          expect(find.byType(SelectableText), findsNothing);
          expect(fields, findsNWidgets(2));
          expect(
            tester.widget<Text>(passage).textSpan!.toPlainText(),
            isNot(contains('{{')),
          );
          expect(
            tester.getTopLeft(passage).dy,
            greaterThan(tester.getBottomLeft(audio).dy),
          );
          expect(
            tester.widget<TextField>(fields.first).controller!.text,
            'saved',
          );
          await tester.enterText(fields.first, 'primary');
          await tester.pump();
          final first = tester.widget<TextField>(fields.first);
          expect(first.textAlign, TextAlign.left);
          expect(first.decoration!.fillColor, AppColors.surface);
          expect(
            first.decoration!.focusedBorder!.borderSide.color,
            AppColors.brandPrimary,
          );
          await tester.enterText(fields.at(1), 'secondary');
          await tester.pump();
          expect(answer, {0: 'primary', 1: 'secondary'});
          expect(
            tester.widget<TextField>(fields.first).controller!.text,
            'primary',
          );
          await tester.enterText(fields.first, '');
          await tester.pump();
          expect(answer, {1: 'secondary'});
          refresh(() => answer = <int, String>{0: 'restored'});
          await tester.pump();
          expect(
            tester.widget<TextField>(fields.first).controller!.text,
            'restored',
          );
          expect(tester.widget<TextField>(fields.at(1)).controller!.text, '');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
