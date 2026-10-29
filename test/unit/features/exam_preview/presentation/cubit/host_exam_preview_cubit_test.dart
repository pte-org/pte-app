import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_preview/domain/entities/host_exam_summary.dart';
import 'package:pte_app/features/exam_preview/domain/entities/preview_snapshot.dart';
import 'package:pte_app/features/exam_preview/domain/repositories/host_exam_preview_repository.dart';
import 'package:pte_app/features/exam_preview/presentation/cubit/host_exam_preview_cubit.dart';
import 'package:pte_app/features/exam_preview/presentation/cubit/host_exam_preview_state.dart';

class _FakeRepository implements HostExamPreviewRepository {
  _FakeRepository(this.snapshot);

  final PreviewSnapshot snapshot;
  int fetchCalls = 0;

  @override
  Future<List<HostExamSummary>> listExams() async => const [];

  @override
  Future<PreviewSnapshot> fetchPreview(String sessionPublicId) async {
    fetchCalls++;
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

  blocTest<HostExamPreviewCubit, HostExamPreviewState>(
    'Next works on the last item by finishing locally without a write call',
    build: () => HostExamPreviewCubit(repository: _FakeRepository(_snapshot())),
    act: (cubit) async {
      await cubit.load('session-1');
      await cubit.next();
      await cubit.next();
    },
    expect: () => [
      isA<HostExamPreviewLoading>(),
      isA<HostExamPreviewReady>(),
      isA<HostExamPreviewReady>().having(
        (state) => state.currentIndex,
        'index',
        0,
      ),
      isA<HostExamPreviewReady>().having(
        (state) => state.currentIndex,
        'index',
        1,
      ),
      isA<HostExamPreviewFinished>(),
    ],
  );

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
