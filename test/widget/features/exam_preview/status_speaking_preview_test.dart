import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';
import 'package:pte_app/features/exam_preview/data/preview_playback_state.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart';

class _Media extends Mock implements PreviewAudioSession {}

void main() {
  for (final task in ['SUMMARIZE_GROUP_DISCUSSION', 'RESPOND_TO_A_SITUATION']) {
    for (final width in [1280.0, 375.0]) {
      testWidgets(
        '$task at $width keeps completed player and recorder visible',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final media = _Media();
          final playback = ValueNotifier(
            const PreviewPlaybackState(
              phase: PreviewPlaybackPhase.playing,
              position: Duration(seconds: 2),
              duration: Duration(seconds: 6),
            ),
          );
          addTearDown(playback.dispose);
          when(() => media.playback).thenReturn(playback);
          final model = PreviewTaskUiAdapter.adapt(
            PreviewItem(
              orderIndex: 0,
              snapshotItemPublicId: 'item',
              sourceQuestionPublicId: 'question',
              section: 'SPEAKING',
              taskType: task,
              taskTypeCode: task,
              taskTypeDisplayName: null,
              title: null,
              promptText: 'Situation text',
              audioUrl: 'https://media.test/prompt.wav',
              imageUrl: null,
              minWordCount: null,
              maxWordCount: null,
              options: [],
              runtime: null,
              runtimeMappingVersion: null,
              runtimeMappingStatus: null,
              prepSeconds: 20,
              responseSeconds: 40,
              preListenSeconds: 3,
              preRecordSeconds: 10,
              audioDurationSeconds: 6,
              audioUrlExpiresAt: null,
              imageUrlExpiresAt: null,
            ),
          );
          Widget subject({required bool preparing}) => MaterialApp(
            home: Scaffold(
              body: HostPreviewTaskDispatcher(
                model: model,
                answer: null,
                onAnswerChanged: (_) {},
                mediaSession: media,
                isPreparing: preparing,
                remainingSeconds: preparing ? 15 : 35,
                isRecording: !preparing,
              ),
            ),
          );
          await tester.pumpWidget(subject(preparing: true));
          expect(find.byKey(const ValueKey('pteStatusPlayer')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('pteStatusRecorder')),
            findsOneWidget,
          );
          expect(find.text('Status: Playing'), findsOneWidget);
          expect(find.byType(Slider), findsOneWidget);
          expect(find.byKey(const ValueKey('pteAudioPanel')), findsNothing);
          if (task == 'SUMMARIZE_GROUP_DISCUSSION') {
            expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
            expect(find.text('Situation text'), findsNothing);
          } else {
            expect(find.text('Situation text'), findsOneWidget);
            final passage = tester.widget<Text>(find.text('Situation text'));
            expect(passage.style?.fontSize, 20);
            expect(passage.textAlign, TextAlign.left);
            final bounds = tester.getRect(find.text('Situation text'));
            expect(bounds.width, lessThanOrEqualTo(1080));
            expect(bounds.center.dx, closeTo(width / 2, 1));
          }
          playback.value = playback.value.copyWith(
            phase: PreviewPlaybackPhase.completed,
          );
          await tester.pumpWidget(subject(preparing: false));
          await tester.pump();
          expect(find.text('Status: Completed'), findsOneWidget);
          expect(find.text('Recording 35 seconds left'), findsOneWidget);
          expect(find.byKey(const ValueKey('pteStatusPlayer')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('pteStatusRecorder')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
