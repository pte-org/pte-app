import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/widgets/exam/stimulus_spec.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/task_view_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/presentation/model/preview_task_ui_adapter.dart';
import 'package:pte_app/features/exam_preview/presentation/widgets/host_preview_task_dispatcher.dart';

PreviewItem _item(String code, String prompt) => PreviewItem(
  orderIndex: 0,
  snapshotItemPublicId: code,
  sourceQuestionPublicId: 'q',
  section: 'LISTENING',
  taskType: code,
  taskTypeCode: code,
  taskTypeDisplayName: null,
  title: null,
  promptText: prompt,
  audioUrl: 'https://media.test/audio.wav',
  imageUrl: null,
  minWordCount: 50,
  maxWordCount: 70,
  options: const [
    PreviewOption(orderIndex: 0, blankIndex: 0, text: 'Option one'),
    PreviewOption(orderIndex: 1, blankIndex: 0, text: 'Option two'),
  ],
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
  const codes = [
    'SUMMARIZE_SPOKEN_TEXT',
    'MC_LISTENING_MULTIPLE',
    'FILL_IN_THE_BLANKS_TYPE_IN',
    'HIGHLIGHT_CORRECT_SUMMARY',
    'MC_LISTENING_SINGLE',
    'SELECT_MISSING_WORD',
    'HIGHLIGHT_INCORRECT_WORDS',
    'WRITE_FROM_DICTATION',
  ];
  for (final code in codes) {
    final showsTranscript =
        code == 'FILL_IN_THE_BLANKS_TYPE_IN' ||
        code == 'HIGHLIGHT_INCORRECT_WORDS';
    final choice =
        code == 'MC_LISTENING_SINGLE' || code == 'MC_LISTENING_MULTIPLE';
    final prompt = showsTranscript
        ? 'TRANSCRIPT with {{0}} words.'
        : 'TRANSCRIPT paragraph one.\n\nTRANSCRIPT paragraph two.\n\nWhich answer fits?';
    testWidgets('$code shows only its permitted Listening text', (
      tester,
    ) async {
      final item = _item(code, prompt);
      final host = PreviewTaskUiAdapter.adapt(item);
      final candidate = TaskViewUiAdapter.adapt(
        TaskView(
          pinnedItemPublicId: 'i',
          orderIndex: 0,
          totalTasks: 8,
          section: 'LISTENING',
          taskType: code,
          title: code,
          promptText: prompt,
          prepSeconds: 0,
          responseSeconds: 60,
        ),
      );
      final expected = showsTranscript
          ? [prompt]
          : choice
          ? ['Which answer fits?']
          : <String>[];
      for (final stimulus in [host.stimulus, candidate.stimulus]) {
        expect(
          stimulus.parts
              .where((part) => part.kind == StimulusPartKind.text)
              .map((part) => part.content)
              .toList(),
          expected,
        );
      }
      // Presentation filtering leaves the original frozen question intact.
      expect(host.item.promptText, prompt);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HostPreviewTaskDispatcher(
              model: host,
              answer: null,
              onAnswerChanged: (_) {},
            ),
          ),
        ),
      );
      expect(
        find.textContaining('TRANSCRIPT'),
        showsTranscript ? findsWidgets : findsNothing,
      );
      expect(
        find.text('Which answer fits?'),
        choice ? findsOneWidget : findsNothing,
      );
      if (code == 'HIGHLIGHT_CORRECT_SUMMARY' ||
          code == 'SELECT_MISSING_WORD' ||
          choice) {
        expect(find.text('Option one'), findsOneWidget);
        expect(find.text('Option two'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
