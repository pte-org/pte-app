import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/media_repository_impl.dart';
import 'package:pte_app/core/network/raw_upload_client.dart';
import 'package:pte_app/dev/mock_backend/mock_backend_adapter.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/audio_prompt_repository_impl.dart';
import 'package:pte_app/features/exam_attempt/data/repositories/exam_attempt_repository_impl.dart';
import 'package:pte_app/features/report/data/repositories/report_repository_impl.dart';

import 'mock_backend_harness.dart';

/// Student-side flows (attempt lifecycle, answers, audio prompts, media
/// upload, report) through the app's real repositories against
/// `MockBackendAdapter`.
void main() {
  late MockBackendAdapter adapter;
  late ApiClient apiClient;

  setUp(() {
    final backend = createMockBackend();
    adapter = backend.adapter;
    apiClient = backend.apiClient;
  });

  test(
    'the full exam serves all 23 task types once, then a fully scored report',
    () async {
      final exam = ExamAttemptRepositoryImpl(apiClient: apiClient);
      var response = await exam.startOrResumeAttempt('mock-full-exam');
      final taskTypes = <String>[];
      while (!response.completed) {
        final task = response.task!;
        taskTypes.add(task.taskType);
        expect(task.orderIndex, taskTypes.length - 1);
        await apiClient.submitAnswer(
          attemptPublicId: response.attemptPublicId,
          pinnedItemPublicId: task.pinnedItemPublicId,
          payload: '{}',
        );
        response = await exam.fetchNextTask(response.attemptPublicId);
      }
      expect(taskTypes, hasLength(23));
      expect(taskTypes.toSet(), hasLength(23));

      final report = await ReportRepositoryImpl(
        apiClient: apiClient,
      ).fetchReport(response.attemptPublicId);
      expect(report!.overall.sufficientData, isTrue);
      expect(
        report.communicativeSkills.every((skill) => skill.sufficientData),
        isTrue,
      );
    },
  );

  test(
    'resumes an unfinished attempt; untested sections report insufficient data',
    () async {
      final exam = ExamAttemptRepositoryImpl(apiClient: apiClient);
      final started = await exam.startOrResumeAttempt('mock-reading');
      final second = await exam.fetchNextTask(started.attemptPublicId);
      final resumed = await exam.startOrResumeAttempt('mock-reading');
      expect(resumed.attemptPublicId, started.attemptPublicId);
      expect(resumed.task!.pinnedItemPublicId, second.task!.pinnedItemPublicId);

      final reports = ReportRepositoryImpl(apiClient: apiClient);
      expect(await reports.fetchReport(started.attemptPublicId), isNull);
      await exam.forceSubmit(started.attemptPublicId);
      final report = await reports.fetchReport(started.attemptPublicId);
      final speaking = report!.communicativeSkills.singleWhere(
        (skill) => skill.skill == 'Speaking',
      );
      expect(speaking.sufficientData, isFalse);
    },
  );

  test('rejects unknown and not-yet-open sessions', () async {
    final exam = ExamAttemptRepositoryImpl(apiClient: apiClient);
    await expectLater(
      exam.startOrResumeAttempt('does-not-exist'),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      exam.startOrResumeAttempt('mock-scheduled-next-week'),
      throwsA(isA<ConflictException>()),
    );
  });

  test(
    'audio-prompt tasks play a bundled asset; Describe Image carries an image URL',
    () async {
      final tasks = await walkAttempt(apiClient, 'mock-speaking');
      final repeatSentence = tasks.singleWhere(
        (task) => task.taskType == 'REPEAT_SENTENCE',
      );
      expect(repeatSentence.audioPromptRef, isNotNull);
      expect(
        tasks.singleWhere((task) => task.taskType == 'DESCRIBE_IMAGE').imageUrl,
        startsWith('https://'),
      );

      final url = await AudioPromptRepositoryImpl(apiClient: apiClient)
          .playAudio(
            attemptPublicId: 'any-attempt',
            pinnedItemPublicId: repeatSentence.pinnedItemPublicId,
            playRequestId: 'play-1',
          );
      expect(Uri.parse(url).scheme, 'asset');
    },
  );

  test('presign, raw PUT and complete succeed without MinIO', () async {
    final media = MediaRepositoryImpl(apiClient: apiClient);
    final presign = await media.requestPresign('audio/wav');

    final directory = await Directory.systemTemp.createTemp(
      'mock_backend_test',
    );
    addTearDown(() => directory.delete(recursive: true));
    final recording = await File(
      '${directory.path}/answer.wav',
    ).writeAsBytes(List.filled(64, 0xFF));

    await RawUploadClient(
      dio: Dio()..httpClientAdapter = adapter,
    ).putFile(presign.uploadUrl, recording, contentType: 'audio/wav');
    await media.completeUpload(presign.mediaPublicId);
  });
}
