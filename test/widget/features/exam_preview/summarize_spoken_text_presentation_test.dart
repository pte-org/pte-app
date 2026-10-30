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
    'audio summary hides script and Stop while preserving pause, resume and replay',
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
        taskType: 'SUMMARIZE_SPOKEN_TEXT',
        taskTypeCode: 'SUMMARIZE_SPOKEN_TEXT',
        taskTypeDisplayName: null,
        title: null,
        promptText: 'TRANSCRIPT MUST REMAIN HIDDEN',
        audioUrl: 'https://media.test/audio.wav',
        imageUrl: null,
        minWordCount: 50,
        maxWordCount: 70,
        options: [],
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
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HostPreviewTaskDispatcher(
              model: PreviewTaskUiAdapter.adapt(item),
              answer: '',
              onAnswerChanged: (_) {},
              mediaSession: media,
            ),
          ),
        ),
      );
      expect(find.text('TRANSCRIPT MUST REMAIN HIDDEN'), findsNothing);
      expect(find.byType(SelectableText), findsNothing);
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
      expect(tester.takeException(), isNull);
    },
  );
}
