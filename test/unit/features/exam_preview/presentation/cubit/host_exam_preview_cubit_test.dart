import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_preview/domain/entities/host_exam_summary.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/domain/repositories/host_exam_preview_repository.dart';
import 'package:pte_app/features/exam_preview/presentation/cubit/host_exam_preview_cubit.dart';
import 'package:pte_app/features/exam_preview/presentation/cubit/host_exam_preview_state.dart';

class _FakeRepository implements HostExamPreviewRepository {
  _FakeRepository(this.snapshot, {this.exams = const []});

  final PreviewSnapshot snapshot;
  int fetchCalls = 0;
  final List<HostExamSummary> exams;
  String? fetchedId;

  @override
  Future<List<HostExamSummary>> listExams() async => exams;

  @override
  Future<PreviewSnapshot> fetchPreview(String sessionPublicId) async {
    fetchCalls++;
    fetchedId = sessionPublicId;
    return snapshot;
  }
}

PreviewItem _item(String id, int order) => PreviewItem(
  orderIndex: order,
  snapshotItemPublicId: id,
  sourceQuestionPublicId: 'question-$id',
  section: 'READING',
  taskType: 'MC_READING_SINGLE',
  taskTypeCode: 'MC_READING_SINGLE',
  taskTypeDisplayName: 'Multiple choice',
  title: 'Question $id',
  promptText: 'Choose one.',
  audioUrl: null,
  imageUrl: null,
  minWordCount: null,
  maxWordCount: null,
  options: const [PreviewOption(orderIndex: 0, blankIndex: null, text: 'A')],
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
);

PreviewSnapshot _snapshot() => PreviewSnapshot(
  snapshotPublicId: 'snapshot-1',
  name: 'Preview exam',
  version: 1,
  items: [_item('item-2', 2), _item('item-1', 1)],
);

void main() {
  for (final input in [' e2e-local ', 'session-1']) {
    test('entry resolves $input within the host organization', () async {
      final repository = _FakeRepository(
        _snapshot(),
        exams: const [
          HostExamSummary(
            publicId: 'session-1',
            sessionCode: 'E2E-LOCAL',
            name: 'Exam',
            status: 'SCHEDULED',
            examVersionPublicId: 'snapshot-1',
          ),
        ],
      );
      final cubit = HostExamPreviewCubit(repository: repository);
      addTearDown(cubit.close);
      await cubit.loadForEntry(input);
      expect(cubit.state, isA<HostExamPreviewReady>());
      expect(repository.fetchedId, 'session-1');
    });
  }
  test('unknown exam code does not fetch or create an attempt', () async {
    final repository = _FakeRepository(_snapshot());
    final cubit = HostExamPreviewCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.loadForEntry('OTHER-TENANT');
    expect(cubit.state, isA<HostExamPreviewError>());
    expect(repository.fetchCalls, 0);
  });
  test('draft without a snapshot does not load task content', () async {
    final repository = _FakeRepository(
      _snapshot(),
      exams: const [
        HostExamSummary(
          publicId: 'draft',
          sessionCode: 'DRAFT',
          name: 'Draft',
          status: 'DRAFT',
          examVersionPublicId: null,
        ),
      ],
    );
    final cubit = HostExamPreviewCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.loadForEntry('DRAFT');
    expect(cubit.state, isA<HostExamPreviewError>());
    expect(repository.fetchCalls, 0);
  });
  test(
    'answers are keyed by snapshot and item and survive local navigation',
    () async {
      final repository = _FakeRepository(_snapshot());
      final cubit = HostExamPreviewCubit(repository: repository);
      addTearDown(cubit.close);

      await cubit.load('session-1');
      cubit.setAnswer(<int>[1]);
      await cubit.next();

      final state = cubit.state as HostExamPreviewReady;
      expect(state.currentItem.snapshotItemPublicId, 'item-2');
      expect(state.answers['snapshot-1:item-1'], [1]);
      expect(repository.fetchCalls, 1);
    },
  );

  test(
    'last Next loops to first, preserves answers and never refetches',
    () async {
      final repository = _FakeRepository(_snapshot());
      final cubit = HostExamPreviewCubit(repository: repository);
      addTearDown(cubit.close);
      await cubit.load('session-1');
      cubit.setAnswer(<int>[0]);
      await cubit.next();
      cubit.setAnswer(<int>[1]);
      final lastEpoch = (cubit.state as HostExamPreviewReady).epoch;
      await cubit.next();
      final first = cubit.state as HostExamPreviewReady;
      expect(first.currentIndex, 0);
      expect(first.epoch, greaterThan(lastEpoch));
      expect(first.isTransitioning, isFalse);
      expect(cubit.answerFor(first.currentItem), [0]);
      await cubit.previous();
      expect((cubit.state as HostExamPreviewReady).currentIndex, 1);
      final second = cubit.state as HostExamPreviewReady;
      expect(cubit.answerFor(second.currentItem), [1]);
      expect(repository.fetchCalls, 1);
      await cubit.finish();
      expect(cubit.state, isA<HostExamPreviewFinished>());
    },
  );

  test('single-item preview loops and restarts its timer', () async {
    final snapshot = PreviewSnapshot(
      snapshotPublicId: 's',
      name: 'Single',
      version: 1,
      items: [_item('i', 0).copyWithForTest(responseSeconds: 10)],
    );
    final cubit = HostExamPreviewCubit(repository: _FakeRepository(snapshot));
    addTearDown(cubit.close);
    await cubit.load('session-1');
    final firstEpoch = (cubit.state as HostExamPreviewReady).epoch;
    await cubit.next();
    final state = cubit.state as HostExamPreviewReady;
    expect(state.currentIndex, 0);
    expect(state.remainingSeconds, 10);
    expect(state.epoch, greaterThan(firstEpoch));
    await cubit.previous();
    final previous = cubit.state as HostExamPreviewReady;
    expect(previous.currentIndex, 0);
    expect(previous.remainingSeconds, 10);
    expect(previous.epoch, greaterThan(state.epoch));
  });

  test('timer expiry stays on the item and does not auto-advance', () async {
    final snapshot = PreviewSnapshot(
      snapshotPublicId: 'snapshot-1',
      name: 'Timed preview',
      version: 1,
      items: [_item('item-1', 1).copyWithForTest(responseSeconds: 1)],
    );
    final cubit = HostExamPreviewCubit(repository: _FakeRepository(snapshot));
    addTearDown(cubit.close);

    await cubit.load('session-1');
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final state = cubit.state as HostExamPreviewReady;
    expect(state.currentIndex, 0);
    expect(state.remainingSeconds, 0);
  });
}

extension on PreviewItem {
  PreviewItem copyWithForTest({required int responseSeconds}) => PreviewItem(
    orderIndex: orderIndex,
    snapshotItemPublicId: snapshotItemPublicId,
    sourceQuestionPublicId: sourceQuestionPublicId,
    section: section,
    taskType: taskType,
    taskTypeCode: taskTypeCode,
    taskTypeDisplayName: taskTypeDisplayName,
    title: title,
    promptText: promptText,
    audioUrl: audioUrl,
    imageUrl: imageUrl,
    minWordCount: minWordCount,
    maxWordCount: maxWordCount,
    options: options,
    runtime: runtime,
    runtimeMappingVersion: runtimeMappingVersion,
    runtimeMappingStatus: runtimeMappingStatus,
    prepSeconds: prepSeconds,
    responseSeconds: responseSeconds,
    preListenSeconds: preListenSeconds,
    preRecordSeconds: preRecordSeconds,
    audioDurationSeconds: audioDurationSeconds,
    audioUrlExpiresAt: audioUrlExpiresAt,
    imageUrlExpiresAt: imageUrlExpiresAt,
  );
}
