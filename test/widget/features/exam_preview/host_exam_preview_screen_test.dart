import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';
import 'package:pte_app/core/widgets/exam/exam_shell.dart';
import 'package:pte_app/core/widgets/exam/exam_header_bar.dart';

import 'package:pte_app/features/exam_preview/domain/entities/host_exam_summary.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/domain/repositories/host_exam_preview_repository.dart';
import 'package:pte_app/features/exam_preview/presentation/pages/host_exam_preview_screen.dart';

class _FakeRepository implements HostExamPreviewRepository {
  _FakeRepository({this.recording = false});
  final bool recording;
  @override
  Future<List<HostExamSummary>> listExams() async => const [
    HostExamSummary(
      publicId: 'session-1',
      sessionCode: 'E2E-LOCAL',
      name: 'Preview exam',
      status: 'SCHEDULED',
      examVersionPublicId: 'snapshot-1',
    ),
  ];

  @override
  Future<PreviewSnapshot> fetchPreview(String sessionPublicId) async =>
      PreviewSnapshot(
        snapshotPublicId: 'snapshot-1',
        name: 'Preview exam',
        version: 1,
        items: [
          PreviewItem(
            orderIndex: 0,
            snapshotItemPublicId: 'item-1',
            sourceQuestionPublicId: 'question-1',
            section: recording ? 'SPEAKING' : 'READING',
            taskType: recording ? 'READ_ALOUD' : 'MC_READING_SINGLE',
            taskTypeCode: recording ? 'READ_ALOUD' : 'MC_READING_SINGLE',
            taskTypeDisplayName: 'Multiple choice',
            title: 'Question 1',
            promptText: 'Choose one answer.',
            audioUrl: null,
            imageUrl: null,
            minWordCount: null,
            maxWordCount: null,
            options: const [
              PreviewOption(orderIndex: 0, blankIndex: null, text: 'First'),
              PreviewOption(orderIndex: 1, blankIndex: null, text: 'Second'),
            ],
            runtime: null,
            runtimeMappingVersion: null,
            runtimeMappingStatus: null,
            prepSeconds: recording ? 1 : 0,
            responseSeconds: recording ? 1 : 0,
            preListenSeconds: null,
            preRecordSeconds: null,
            audioDurationSeconds: null,
            audioUrlExpiresAt: null,
            imageUrlExpiresAt: null,
          ),
        ],
      );
}

class _MockMedia extends Mock implements PreviewAudioSession {}

void main() {
  testWidgets('late microphone startup cannot reactivate an expired response', (
    tester,
  ) async {
    final media = _MockMedia();
    final started = Completer<String>();
    when(() => media.canPauseRecording).thenReturn(false);
    when(
      () => media.inputLevels,
    ).thenAnswer((_) => const Stream<double>.empty());
    when(
      () => media.position,
    ).thenAnswer((_) => const Stream<Duration>.empty());
    when(() => media.startRecording()).thenAnswer((_) => started.future);
    when(() => media.stopRecording()).thenAnswer((_) async => null);
    when(() => media.dispose()).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: HostExamPreviewScreen(
          sessionInput: 'E2E-LOCAL',
          repository: _FakeRepository(recording: true),
          mediaSession: media,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    verify(() => media.startRecording()).called(1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    verify(() => media.stopRecording()).called(1);
    started.complete('temporary.wav');
    await tester.pump();
    await tester.pump();
    expect(find.text('Completed'), findsOneWidget);
    expect(find.textContaining('Recording 0'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'host recorder pause freezes response time and resumes before stopping',
    (tester) async {
      final media = _MockMedia();
      when(() => media.canPauseRecording).thenReturn(true);
      when(
        () => media.inputLevels,
      ).thenAnswer((_) => const Stream<double>.empty());
      when(
        () => media.position,
      ).thenAnswer((_) => const Stream<Duration>.empty());
      when(
        () => media.startRecording(),
      ).thenAnswer((_) async => 'temporary.wav');
      when(() => media.pauseRecording()).thenAnswer((_) async {});
      when(() => media.resumeRecording()).thenAnswer((_) async {});
      when(() => media.stopRecording()).thenAnswer((_) async => null);
      when(() => media.dispose()).thenAnswer((_) async {});
      await tester.pumpWidget(
        MaterialApp(
          home: HostExamPreviewScreen(
            sessionInput: 'E2E-LOCAL',
            repository: _FakeRepository(recording: true),
            mediaSession: media,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.tap(find.byTooltip('Pause audio'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Paused'), findsOneWidget);
      verifyNever(() => media.stopRecording());
      await tester.tap(find.byTooltip('Play audio'));
      await tester.pump();
      expect(find.text('Recording 1 seconds left'), findsOneWidget);
      await tester.tap(find.byTooltip('Stop recording'));
      await tester.pump();
      expect(find.text('Completed'), findsOneWidget);
      verify(() => media.pauseRecording()).called(1);
      verify(() => media.resumeRecording()).called(1);
      verify(() => media.stopRecording()).called(1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'host recording starts automatically and Next discards it locally',
    (tester) async {
      final media = _MockMedia();
      when(() => media.canPauseRecording).thenReturn(false);
      when(
        () => media.inputLevels,
      ).thenAnswer((_) => const Stream<double>.empty());
      when(
        () => media.position,
      ).thenAnswer((_) => const Stream<Duration>.empty());
      when(
        () => media.startRecording(),
      ).thenAnswer((_) async => 'temporary.wav');
      when(() => media.stopRecording()).thenAnswer((_) async => null);
      when(() => media.stopPlayback()).thenAnswer((_) async {});
      when(() => media.dispose()).thenAnswer((_) async {});
      var exits = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HostExamPreviewScreen(
            sessionInput: 'E2E-LOCAL',
            repository: _FakeRepository(recording: true),
            mediaSession: media,
            onExit: () => exits++,
          ),
        ),
      );
      await tester.pump();
      verifyNever(() => media.startRecording());
      expect(find.text('Start local recording'), findsNothing);
      expect(find.text('Beginning in 1 seconds'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      verify(() => media.startRecording()).called(1);
      expect(find.text('Recording 1 seconds left'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(exits, 0);
      expect(find.text('Beginning in 1 seconds'), findsOneWidget);
      verify(() => media.stopRecording()).called(1);
      await tester.tap(find.byTooltip('Finish exam'));
      await tester.pumpAndSettle();
      expect(exits, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'exam code enters the student shell directly without preview chrome',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HostExamPreviewScreen(
            sessionInput: ' e2e-local ',
            repository: _FakeRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExamShell), findsOneWidget);
      expect(find.byType(ExamHeaderBar), findsOneWidget);
      expect(find.text('Exam preview'), findsNothing);
      expect(find.text('Snapshot available'), findsNothing);
      expect(find.text('Multiple Choice, Single Answer'), findsOneWidget);
      expect(find.text('Question 1'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
    },
  );
}
