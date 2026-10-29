import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_preview/domain/entities/host_exam_summary.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/domain/repositories/host_exam_preview_repository.dart';
import 'package:pte_app/features/exam_preview/presentation/pages/host_exam_preview_screen.dart';

class _FakeRepository implements HostExamPreviewRepository {
  @override
  Future<List<HostExamSummary>> listExams() async => const [];

  @override
  Future<PreviewSnapshot> fetchPreview(String sessionPublicId) async =>
      PreviewSnapshot(
        snapshotPublicId: 'snapshot-1',
        name: 'Preview exam',
        version: 1,
        items: [
          const PreviewItem(
            orderIndex: 0,
            snapshotItemPublicId: 'item-1',
            sourceQuestionPublicId: 'question-1',
            section: 'READING',
            taskType: 'MC_READING_SINGLE',
            taskTypeCode: 'MC_READING_SINGLE',
            taskTypeDisplayName: 'Multiple choice',
            title: 'Question 1',
            promptText: 'Choose one answer.',
            audioUrl: null,
            imageUrl: null,
            minWordCount: null,
            maxWordCount: null,
            options: [
              PreviewOption(orderIndex: 0, blankIndex: null, text: 'First'),
              PreviewOption(orderIndex: 1, blankIndex: null, text: 'Second'),
            ],
            runtime: null,
            runtimeMappingVersion: null,
            runtimeMappingStatus: null,
            prepSeconds: 0,
            responseSeconds: 0,
            preListenSeconds: null,
            preRecordSeconds: null,
            audioDurationSeconds: null,
            audioUrlExpiresAt: null,
            imageUrlExpiresAt: null,
          ),
        ],
      );
}

void main() {
  testWidgets('renders a real snapshot task with local Next/Finish controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HostExamPreviewScreen(
          sessionPublicId: 'session-1',
          repository: _FakeRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preview exam · Host preview'), findsOneWidget);
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Finish preview'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
  });
}
