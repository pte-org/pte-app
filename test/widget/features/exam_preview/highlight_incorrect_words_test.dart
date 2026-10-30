import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/widgets/components/highlightable_word_span.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/transcript_words.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_incorrect_words_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_incorrect_words_state.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/word_selection_list.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart';

class _Dao extends Mock implements AnswerOutboxDao {}

class _Player extends Mock implements AudioPlayerService {}

const _transcript = 'word word word.\nNext line.';
const _item = PreviewItem(
  orderIndex: 0,
  snapshotItemPublicId: 'i',
  sourceQuestionPublicId: 'q',
  section: 'LISTENING',
  taskType: 'HIGHLIGHT_INCORRECT_WORDS',
  taskTypeCode: 'HIGHLIGHT_INCORRECT_WORDS',
  taskTypeDisplayName: null,
  title: null,
  promptText: _transcript,
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

Finder _word(int index) => find.byKey(ValueKey('highlight-word-$index'));
Future<void> _doubleClick(WidgetTester tester, int index) async {
  await tester.tap(_word(index));
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(_word(index));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [375.0, 1280.0]) {
    testWidgets(
      'host has one framed transcript below audio and double-click toggles words at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Object? answer;
        late StateSetter refresh;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  refresh = setState;
                  return HostPreviewTaskDispatcher(
                    model: PreviewTaskUiAdapter.adapt(_item),
                    answer: answer,
                    onAnswerChanged: (next) => setState(() => answer = next),
                  );
                },
              ),
            ),
          ),
        );
        final frame = find.byKey(const ValueKey('highlightTranscriptFrame'));
        final passage = find.byKey(
          const ValueKey('highlightTranscriptPassage'),
        );
        expect(frame, findsOneWidget);
        expect(
          (tester.widget<Container>(frame).decoration! as BoxDecoration).border,
          isNotNull,
        );
        expect(
          tester.getTopLeft(frame).dy,
          greaterThan(
            tester
                .getBottomLeft(find.byKey(const ValueKey('pteAudioPanel')))
                .dy,
          ),
        );
        expect(find.byType(SelectableText), findsNothing);
        expect(find.byType(HighlightableWordSpan), findsNWidgets(5));
        expect(
          tester.widget<Text>(passage).textSpan!.toPlainText(),
          contains('\n'),
        );
        await tester.tap(_word(1));
        await tester.pump(const Duration(milliseconds: 400));
        expect(answer, isNull);
        await _doubleClick(tester, 1);
        expect(answer, [1]);
        expect(
          tester.widget<HighlightableWordSpan>(_word(1)).highlighted,
          isTrue,
        );
        final selectedText = find.descendant(
          of: _word(1),
          matching: find.byType(Text),
        );
        expect(
          tester.widget<Text>(selectedText).style!.backgroundColor,
          AppColors.transcriptWordHighlight,
        );
        expect(
          tester.widget<HighlightableWordSpan>(_word(0)).highlighted,
          isFalse,
        );
        await _doubleClick(tester, 3);
        expect(answer, [1, 3]);
        await _doubleClick(tester, 1);
        expect(answer, [3]);
        refresh(() => answer = <int>[2]);
        await tester.pump();
        expect(
          tester.widget<HighlightableWordSpan>(_word(2)).highlighted,
          isTrue,
        );
        expect(
          tester.widget<HighlightableWordSpan>(_word(3)).highlighted,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'candidate double-click persists original word indices and restores selection',
    (tester) async {
      final dao = _Dao();
      final player = _Player();
      when(
        () => dao.upsertAnswer(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
      when(() => player.play(any())).thenAnswer((_) async {});
      when(
        () => player.hasFinishedPlaying,
      ).thenAnswer((_) => const Stream<bool>.empty());
      when(
        () => player.position,
      ).thenAnswer((_) => const Stream<Duration>.empty());
      when(
        () => player.duration,
      ).thenAnswer((_) => const Stream<Duration?>.empty());
      when(() => player.close()).thenAnswer((_) async {});
      final cubit = HighlightIncorrectWordsCubit(
        outboxDao: dao,
        audioPlayerService: player,
        attemptPublicId: 'a',
        pinnedItemPublicId: 'i',
        audioSource: '',
        initialPayload: '2',
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:
                BlocBuilder<
                  HighlightIncorrectWordsCubit,
                  HighlightIncorrectWordsState
                >(
                  bloc: cubit,
                  builder: (context, state) => WordSelectionList(
                    words: splitTranscriptWords(_transcript),
                    transcript: _transcript,
                    selectedIndices: state.selectedWordIndices,
                    onToggle: cubit.toggleWord,
                  ),
                ),
          ),
        ),
      );
      expect(
        tester.widget<HighlightableWordSpan>(_word(2)).highlighted,
        isTrue,
      );
      await _doubleClick(tester, 1);
      expect(cubit.state.selectedWordIndices, {1, 2});
      verify(
        () => dao.upsertAnswer(
          attemptPublicId: 'a',
          pinnedItemPublicId: 'i',
          payload: '1,2',
        ),
      ).called(1);
      await _doubleClick(tester, 2);
      expect(cubit.state.selectedWordIndices, {1});
      verify(
        () => dao.upsertAnswer(
          attemptPublicId: 'a',
          pinnedItemPublicId: 'i',
          payload: '1',
        ),
      ).called(1);
    },
  );
}
