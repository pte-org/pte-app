import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';
import 'package:pte_app/features/exam_preview/data/preview_playback_state.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_stimulus.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart';

class _Media extends Mock implements PreviewAudioSession {}

void main() {
  for (final code in [
    'SUMMARIZE_SPOKEN_TEXT',
    'MC_LISTENING_MULTIPLE',
    'FILL_IN_THE_BLANKS_TYPE_IN',
    'HIGHLIGHT_CORRECT_SUMMARY',
    'MC_LISTENING_SINGLE',
    'SELECT_MISSING_WORD',
    'HIGHLIGHT_INCORRECT_WORDS',
    'WRITE_FROM_DICTATION',
  ]) {
    testWidgets(
      '$code player has Pause/Play and allows replay only after completion',
      (tester) async {
        final media = _Media();
        final playback = ValueNotifier(
          const PreviewPlaybackState(
            phase: PreviewPlaybackPhase.playing,
            position: Duration(seconds: 2),
            duration: Duration(seconds: 8),
          ),
        );
        addTearDown(playback.dispose);
        when(() => media.playback).thenReturn(playback);
        when(() => media.canControlPlayback).thenReturn(true);
        when(() => media.canReplayPlayback).thenReturn(true);
        when(() => media.replayPlayback()).thenAnswer((_) async {
          playback.value = playback.value.copyWith(
            phase: PreviewPlaybackPhase.playing,
            position: Duration.zero,
          );
        });
        when(() => media.togglePlaybackPause()).thenAnswer((_) async {
          playback.value = playback.value.copyWith(
            phase: playback.value.phase == PreviewPlaybackPhase.playing
                ? PreviewPlaybackPhase.paused
                : PreviewPlaybackPhase.playing,
          );
        });
        when(() => media.stopPlaybackByHost()).thenAnswer((_) async {
          playback.value = playback.value.copyWith(
            phase: PreviewPlaybackPhase.stopped,
          );
        });
        final item = PreviewItem(
          orderIndex: 0,
          snapshotItemPublicId: 'audio',
          sourceQuestionPublicId: 'question',
          section: 'LISTENING',
          taskType: code,
          taskTypeCode: code,
          taskTypeDisplayName: null,
          title: null,
          promptText: null,
          audioUrl: 'https://media.test/audio.wav',
          imageUrl: null,
          minWordCount: null,
          maxWordCount: null,
          options: [],
          runtime: null,
          runtimeMappingVersion: null,
          runtimeMappingStatus: null,
          prepSeconds: 0,
          responseSeconds: 30,
          preListenSeconds: null,
          preRecordSeconds: null,
          audioDurationSeconds: 999,
          audioUrlExpiresAt: null,
          imageUrlExpiresAt: null,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HostPreviewStimulus(
                model: PreviewTaskUiAdapter.adapt(item),
                mediaSession: media,
              ),
            ),
          ),
        );
        expect(find.text('0:02 / 0:08'), findsOneWidget);
        expect(find.byTooltip('Stop audio'), findsNothing);
        expect(find.byIcon(Icons.stop), findsNothing);
        expect(find.byTooltip('Replay audio'), findsNothing);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          0.25,
        );
        await tester.tap(find.byTooltip('Pause audio'));
        await tester.pump();
        expect(find.text('Paused'), findsOneWidget);
        expect(find.byTooltip('Stop audio'), findsNothing);
        expect(find.byTooltip('Replay audio'), findsNothing);
        await tester.tap(find.byTooltip('Play audio'));
        await tester.pump();
        expect(find.text('Playing'), findsOneWidget);
        verify(() => media.togglePlaybackPause()).called(2);
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.stopped,
        );
        await tester.pump();
        expect(find.byTooltip('Replay audio'), findsNothing);
        playback.value = playback.value.copyWith(
          phase: PreviewPlaybackPhase.completed,
          position: const Duration(seconds: 8),
        );
        await tester.pump();
        expect(find.text('Completed'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byTooltip('Replay audio'),
            matching: find.byIcon(Icons.play_arrow),
          ),
          findsOneWidget,
        );
        expect(find.byTooltip('Stop audio'), findsNothing);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          1,
        );
        await tester.tap(find.byTooltip('Replay audio'));
        await tester.pump();
        expect(find.text('0:00 / 0:08'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          0,
        );
        verify(() => media.replayPlayback()).called(1);
        verifyNever(() => media.stopPlaybackByHost());
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'audio prompt preview changes one panel from player to recorder',
    (tester) async {
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
      when(() => media.canControlPlayback).thenReturn(true);
      when(() => media.canReplayPlayback).thenReturn(false);
      final model = PreviewTaskUiAdapter.adapt(
        const PreviewItem(
          orderIndex: 0,
          snapshotItemPublicId: 'repeat-sentence',
          sourceQuestionPublicId: 'question',
          section: 'SPEAKING',
          taskType: 'REPEAT_SENTENCE',
          taskTypeCode: 'REPEAT_SENTENCE',
          taskTypeDisplayName: null,
          title: null,
          promptText: null,
          audioUrl: 'https://media.test/audio.wav',
          imageUrl: null,
          minWordCount: null,
          maxWordCount: null,
          options: [],
          runtime: null,
          runtimeMappingVersion: null,
          runtimeMappingStatus: null,
          prepSeconds: 10,
          responseSeconds: 15,
          preListenSeconds: null,
          preRecordSeconds: null,
          audioDurationSeconds: 6,
          audioUrlExpiresAt: null,
          imageUrlExpiresAt: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HostPreviewTaskDispatcher(
              model: model,
              answer: null,
              onAnswerChanged: (_) {},
              mediaSession: media,
              isPreparing: true,
              remainingSeconds: 10,
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
      expect(find.text('Playing'), findsOneWidget);
      expect(find.text('Audio Recorder'), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.replay), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.pause))
            .onPressed,
        isNull,
      );

      playback.value = playback.value.copyWith(
        phase: PreviewPlaybackPhase.completed,
        position: const Duration(seconds: 6),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('pteAudioPanel')), findsOneWidget);
      expect(find.text('Audio Player'), findsNothing);
      expect(find.text('Audio Recorder'), findsOneWidget);
      expect(find.text('Beginning in 10 seconds'), findsOneWidget);
      expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
