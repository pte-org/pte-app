import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/features/exam_attempt/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/read_aloud_state.dart';

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

class _MockPendingMediaUploadDao extends Mock implements PendingMediaUploadDao {}

class _MockMediaUploadCoordinator extends Mock implements MediaUploadCoordinator {}

void main() {
  late _MockAudioRecorderService recorder;
  late _MockPendingMediaUploadDao mediaDao;
  late _MockMediaUploadCoordinator coordinator;

  setUp(() {
    recorder = _MockAudioRecorderService();
    mediaDao = _MockPendingMediaUploadDao();
    coordinator = _MockMediaUploadCoordinator();
    when(() => mediaDao.watchRow(any(), any())).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
    when(
      () => mediaDao.upsertRecorded(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        localFilePath: any(named: 'localFilePath'),
      ),
    ).thenAnswer((_) async {});
    when(() => coordinator.attemptUpload(any(), any())).thenAnswer((_) async {});
  });

  ReadAloudCubit buildCubit() => ReadAloudCubit(
    recorder: recorder,
    mediaDao: mediaDao,
    coordinator: coordinator,
    attemptPublicId: 'attempt-1',
    pinnedItemPublicId: 'item-1',
    resolveFilePath: (attemptPublicId, pinnedItemPublicId) async => '/tmp/${attemptPublicId}_$pinnedItemPublicId.wav',
  );

  group('ReadAloudCubit — recording phase transitions', () {
    blocTest<ReadAloudCubit, ReadAloudState>(
      'startRecording emits recording after the recorder actually starts',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) => cubit.startRecording(),
      expect: () => [const ReadAloudState(recordingPhase: RecordingPhase.recording)],
    );

    blocTest<ReadAloudCubit, ReadAloudState>(
      'stopRecording with a successful file path emits recorded, upserts the DAO row, and triggers upload',
      setUp: () => when(() => recorder.stop()).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav'),
      build: buildCubit,
      act: (cubit) => cubit.stopRecording(),
      expect: () => [const ReadAloudState(recordingPhase: RecordingPhase.recorded)],
      verify: (_) {
        verify(
          () => mediaDao.upsertRecorded(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            localFilePath: '/tmp/attempt-1_item-1.wav',
          ),
        ).called(1);
        verify(() => coordinator.attemptUpload('attempt-1', 'item-1')).called(1);
      },
    );

    blocTest<ReadAloudCubit, ReadAloudState>(
      'stopRecording returning null from a fresh (never-recorded) state falls back to idle',
      setUp: () => when(() => recorder.stop()).thenAnswer((_) async => null),
      build: buildCubit,
      act: (cubit) => cubit.stopRecording(),
      expect: () => [const ReadAloudState(recordingPhase: RecordingPhase.idle)],
      verify: (_) {
        verifyNever(
          () => mediaDao.upsertRecorded(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            localFilePath: any(named: 'localFilePath'),
          ),
        );
      },
    );

    blocTest<ReadAloudCubit, ReadAloudState>(
      'a failed re-record (stop() returns null after an earlier successful recording) preserves the '
      'recorded phase instead of regressing to idle',
      setUp: () => when(() => recorder.stop()).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav'),
      build: buildCubit,
      act: (cubit) async {
        // First recording succeeds.
        await cubit.stopRecording();
        // A re-record attempt this time fails to produce a file.
        when(() => recorder.stop()).thenAnswer((_) async => null);
        await cubit.stopRecording();
      },
      expect: () => [
        const ReadAloudState(recordingPhase: RecordingPhase.recorded),
        // No second emission — state.copyWith is never called since the
        // cubit must not re-emit/regress to idle here.
      ],
    );
  });
}
