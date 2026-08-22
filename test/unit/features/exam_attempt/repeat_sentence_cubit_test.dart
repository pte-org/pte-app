import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/features/exam_attempt/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/recording_phase.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/repeat_sentence_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/repeat_sentence_state.dart';

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

  RepeatSentenceCubit buildCubit() => RepeatSentenceCubit(
    recorder: recorder,
    mediaDao: mediaDao,
    coordinator: coordinator,
    attemptPublicId: 'attempt-1',
    pinnedItemPublicId: 'item-1',
    resolveFilePath: (attemptPublicId, pinnedItemPublicId) async => '/tmp/${attemptPublicId}_$pinnedItemPublicId.wav',
  );

  group('RepeatSentenceCubit — recording phase transitions', () {
    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'startRecording emits recording after the recorder actually starts',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) => cubit.startRecording(),
      expect: () => [const RepeatSentenceState(recordingPhase: RecordingPhase.recording)],
    );

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'stopRecording with a successful file path emits recorded, upserts the DAO row, and triggers upload',
      setUp: () => when(() => recorder.stop()).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav'),
      build: buildCubit,
      act: (cubit) => cubit.stopRecording(),
      expect: () => [const RepeatSentenceState(recordingPhase: RecordingPhase.recorded)],
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

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'stopRecording returning null from a fresh (never-recorded) state falls back to idle',
      setUp: () => when(() => recorder.stop()).thenAnswer((_) async => null),
      build: buildCubit,
      act: (cubit) => cubit.stopRecording(),
      expect: () => [const RepeatSentenceState(recordingPhase: RecordingPhase.idle)],
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

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
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
        const RepeatSentenceState(recordingPhase: RecordingPhase.recorded),
        // No second emission — state.copyWith is never called since the
        // cubit must not re-emit/regress to idle here.
      ],
    );
  });

  group('RepeatSentenceCubit — onTimerSnapshot auto-record', () {
    const responseSnapshot = TimerSnapshot(phase: TimerPhase.response, remaining: Duration(seconds: 15), currentOrderIndex: 1);
    const responseExpiredSnapshot = TimerSnapshot(phase: TimerPhase.response, remaining: Duration.zero, currentOrderIndex: 1);
    const prepSnapshot = TimerSnapshot(phase: TimerPhase.prep, remaining: Duration(seconds: 5), currentOrderIndex: 1);

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'idle + response phase starts recording',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(responseSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [const RepeatSentenceState(recordingPhase: RecordingPhase.recording)],
      verify: (_) => verify(() => recorder.start(any())).called(1),
    );

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'recording + response phase + remaining expired stops recording',
      setUp: () => when(() => recorder.stop()).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav'),
      seed: () => const RepeatSentenceState(recordingPhase: RecordingPhase.recording),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(responseExpiredSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [const RepeatSentenceState(recordingPhase: RecordingPhase.recorded)],
      verify: (_) => verify(() => recorder.stop()).called(1),
    );

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'prep phase (covers the whole listen sequence) is always a no-op regardless of recording phase',
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(prepSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => <RepeatSentenceState>[],
      verify: (_) {
        verifyNever(() => recorder.start(any()));
        verifyNever(() => recorder.stop());
      },
    );

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'already recorded — repeated snapshots are a no-op, never re-stops',
      seed: () => const RepeatSentenceState(recordingPhase: RecordingPhase.recorded),
      build: buildCubit,
      act: (cubit) {
        cubit.onTimerSnapshot(responseSnapshot);
        cubit.onTimerSnapshot(responseExpiredSnapshot);
      },
      wait: const Duration(milliseconds: 1),
      expect: () => <RepeatSentenceState>[],
      verify: (_) {
        verifyNever(() => recorder.start(any()));
        verifyNever(() => recorder.stop());
      },
    );

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'resume-after-expiry: idle + response + remaining already zero on the first snapshot only starts, '
      'never stops in the same call',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(responseExpiredSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [const RepeatSentenceState(recordingPhase: RecordingPhase.recording)],
      verify: (_) {
        verify(() => recorder.start(any())).called(1);
        verifyNever(() => recorder.stop());
      },
    );

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'recording + response phase + non-expired remaining on a repeated mid-recording tick is a no-op '
      '(neither starts again nor stops)',
      seed: () => const RepeatSentenceState(recordingPhase: RecordingPhase.recording),
      build: buildCubit,
      act: (cubit) {
        cubit.onTimerSnapshot(responseSnapshot);
        cubit.onTimerSnapshot(const TimerSnapshot(phase: TimerPhase.response, remaining: Duration(seconds: 8), currentOrderIndex: 1));
      },
      wait: const Duration(milliseconds: 1),
      expect: () => <RepeatSentenceState>[],
      verify: (_) {
        verifyNever(() => recorder.start(any()));
        verifyNever(() => recorder.stop());
      },
    );

    blocTest<RepeatSentenceCubit, RepeatSentenceState>(
      'two response-phase snapshots delivered back-to-back with no await between them '
      '(simulating the initial-forward-then-immediate-stream-event case) still only starts recording once — '
      'guards against a synchronous re-entrant double-start before the first startRecording() await resolves',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) {
        // Deliberately no `await`/`wait` between these two synchronous calls
        // — onTimerSnapshot itself is synchronous (fires-and-forgets
        // startRecording via unawaited), so both calls run to completion
        // before startRecording's first `await` inside it has a chance to
        // flip state.recordingPhase away from idle.
        cubit.onTimerSnapshot(responseSnapshot);
        cubit.onTimerSnapshot(responseSnapshot);
      },
      wait: const Duration(milliseconds: 1),
      expect: () => [const RepeatSentenceState(recordingPhase: RecordingPhase.recording)],
      verify: (_) => verify(() => recorder.start(any())).called(1),
    );
  });
}
