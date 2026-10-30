import 'package:pte_app/core/widgets/components/choice_row.dart';
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
  testWidgets(
    'listening MC shows only question, plain choices and player without Stop',
    (tester) async {
      final media = _Media();
      final playback = ValueNotifier(
        const PreviewPlaybackState(
          phase: PreviewPlaybackPhase.playing,
          position: Duration(seconds: 3),
          duration: Duration(seconds: 80),
        ),
      );
      addTearDown(playback.dispose);
      when(() => media.playback).thenReturn(playback);
      when(() => media.canControlPlayback).thenReturn(true);
      when(() => media.canReplayPlayback).thenReturn(true);
      when(() => media.togglePlaybackPause()).thenAnswer((_) async {
        playback.value = playback.value.copyWith(
          phase: playback.value.phase == PreviewPlaybackPhase.playing
              ? PreviewPlaybackPhase.paused
              : PreviewPlaybackPhase.playing,
        );
      });
      when(() => media.replayPlayback()).thenAnswer((_) async {
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.playing,
          position: Duration.zero,
        );
      });
      const item = PreviewItem(
        orderIndex: 0,
        snapshotItemPublicId: 'i',
        sourceQuestionPublicId: 'q',
        section: 'LISTENING',
        taskType: 'MC_LISTENING_MULTIPLE',
        taskTypeCode: 'MC_LISTENING_MULTIPLE',
        taskTypeDisplayName: null,
        title: null,
        promptText:
            'TRANSCRIPT MUST REMAIN HIDDEN\n\nWhich qualities are mentioned',
        audioUrl: 'https://media.test/audio.wav',
        imageUrl: null,
        minWordCount: 50,
        maxWordCount: 70,
        options: [
          PreviewOption(orderIndex: 5, blankIndex: null, text: 'Quality A'),
          PreviewOption(orderIndex: 9, blankIndex: null, text: 'Quality B'),
        ],
        runtime: null,
        runtimeMappingVersion: null,
        runtimeMappingStatus: null,
        prepSeconds: 0,
        responseSeconds: 600,
        preListenSeconds: null,
        preRecordSeconds: null,
        audioDurationSeconds: 80,
        audioUrlExpiresAt: null,
        imageUrlExpiresAt: null,
      );
      Object? answer;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => HostPreviewTaskDispatcher(
                model: PreviewTaskUiAdapter.adapt(item),
                answer: answer,
                onAnswerChanged: (next) => setState(() => answer = next),
                mediaSession: media,
              ),
            ),
          ),
        ),
      );
      expect(find.text('TRANSCRIPT MUST REMAIN HIDDEN'), findsNothing);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('Which qualities are mentioned'), findsOneWidget);
      expect(
        tester
            .widgetList<ChoiceRow>(find.byType(ChoiceRow))
            .every((row) => row.plain),
        isTrue,
      );
      expect(find.byTooltip('Stop audio'), findsNothing);
      await tester.tap(find.byTooltip('Pause audio'));
      await tester.pump();
      expect(playback.value.phase, PreviewPlaybackPhase.paused);
      expect(find.byTooltip('Stop audio'), findsNothing);
      await tester.tap(find.byTooltip('Play audio'));
      await tester.pump();
      expect(playback.value.phase, PreviewPlaybackPhase.playing);
      playback.value = playback.value.copyWith(
        phase: PreviewPlaybackPhase.completed,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Replay audio'));
      await tester.pump();
      verify(() => media.replayPlayback()).called(1);
      verifyNever(() => media.stopPlaybackByHost());
      expect(find.byTooltip('Stop audio'), findsNothing);
      await tester.ensureVisible(find.text('Quality A'));
      await tester.tap(find.text('Quality A'));
      await tester.pump();
      await tester.ensureVisible(find.text('Quality B'));
      await tester.tap(find.text('Quality B'));
      await tester.pump();
      expect(answer, [0, 1]);
      await tester.tap(find.text('Quality B'));
      await tester.pump();
      expect(answer, [0]);
      expect(tester.takeException(), isNull);
    },
  );
}
