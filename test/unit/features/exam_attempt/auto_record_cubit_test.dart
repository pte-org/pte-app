import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/app_database.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/sync/media_upload_coordinator.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/auto_record_state.dart';

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

class _MockPendingMediaUploadDao extends Mock
    implements PendingMediaUploadDao {}

class _MockMediaUploadCoordinator extends Mock
    implements MediaUploadCoordinator {}

// AutoRecordCubit is shared by every auto-record speaking task's screen
// (Read Aloud, Repeat Sentence, Describe Image) — nothing here is
// task-type-specific, so one suite covers all of them. This file replaces
// the formerly-separate read_aloud_cubit_test.dart and
// repeat_sentence_cubit_test.dart, which tested byte-identical behavior
// against two duplicated cubits (22 near-identical cases total); deduped
// here to the 11 actually-distinct branches.
void main() {
  late _MockAudioRecorderService recorder;
  late _MockPendingMediaUploadDao mediaDao;
  late _MockMediaUploadCoordinator coordinator;

  setUp(() {
    recorder = _MockAudioRecorderService();
    mediaDao = _MockPendingMediaUploadDao();
    coordinator = _MockMediaUploadCoordinator();
    when(
      () => mediaDao.watchRow(any(), any()),
    ).thenAnswer((_) => const Stream<PendingMediaUpload?>.empty());
    when(
      () => mediaDao.upsertRecorded(
        attemptPublicId: any(named: 'attemptPublicId'),
        pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
        localFilePath: any(named: 'localFilePath'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => coordinator.attemptUpload(any(), any()),
    ).thenAnswer((_) async {});
  });

  AutoRecordCubit buildCubit() => AutoRecordCubit(
    recorder: recorder,
    mediaDao: mediaDao,
    coordinator: coordinator,
    attemptPublicId: 'attempt-1',
    pinnedItemPublicId: 'item-1',
    resolveFilePath: (attemptPublicId, pinnedItemPublicId) async =>
        '/tmp/${attemptPublicId}_$pinnedItemPublicId.wav',
  );

  group('AutoRecordCubit — recording phase transitions', () {
    blocTest<AutoRecordCubit, AutoRecordState>(
      'startRecording emits recording after the recorder actually starts',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) => cubit.startRecording(),
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.recording),
      ],
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'startRecording reports an unavailable microphone instead of leaking the native error',
      setUp: () => when(
        () => recorder.start(any()),
      ).thenThrow(const AudioInputUnavailableException()),
      build: buildCubit,
      act: (cubit) => cubit.startRecording(),
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.unavailable),
      ],
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'stopRecording with a successful file path emits recorded, upserts the DAO row, and triggers upload',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav'),
      build: buildCubit,
      act: (cubit) => cubit.stopRecording(),
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.recorded),
      ],
      verify: (_) {
        verify(
          () => mediaDao.upsertRecorded(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            localFilePath: '/tmp/attempt-1_item-1.wav',
          ),
        ).called(1);
        verify(
          () => coordinator.attemptUpload('attempt-1', 'item-1'),
        ).called(1);
      },
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'stopRecording returning null from a fresh (never-recorded) state falls back to idle',
      setUp: () => when(() => recorder.stop()).thenAnswer((_) async => null),
      build: buildCubit,
      act: (cubit) => cubit.stopRecording(),
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.idle),
      ],
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

    blocTest<AutoRecordCubit, AutoRecordState>(
      'a failed re-record (stop() returns null after an earlier successful recording) preserves the '
      'recorded phase instead of regressing to idle',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav'),
      build: buildCubit,
      act: (cubit) async {
        // First recording succeeds.
        await cubit.stopRecording();
        // A re-record attempt this time fails to produce a file.
        when(() => recorder.stop()).thenAnswer((_) async => null);
        await cubit.stopRecording();
      },
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.recorded),
        // No second emission — state.copyWith is never called since the
        // cubit must not re-emit/regress to idle here.
      ],
    );
  });

  group('AutoRecordCubit — onTimerSnapshot auto-record', () {
    const responseSnapshot = TimerSnapshot(
      phase: TimerPhase.response,
      remaining: Duration(seconds: 20),
      currentOrderIndex: 1,
    );
    const responseExpiredSnapshot = TimerSnapshot(
      phase: TimerPhase.response,
      remaining: Duration.zero,
      currentOrderIndex: 1,
    );
    const prepSnapshot = TimerSnapshot(
      phase: TimerPhase.prep,
      remaining: Duration(seconds: 5),
      currentOrderIndex: 1,
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'idle + response phase starts recording',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(responseSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.recording),
      ],
      verify: (_) => verify(() => recorder.start(any())).called(1),
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'recording + response phase + remaining expired stops recording',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav'),
      seed: () =>
          const AutoRecordState(recordingPhase: RecordingPhase.recording),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(responseExpiredSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.recorded),
      ],
      verify: (_) => verify(() => recorder.stop()).called(1),
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'prep phase is always a no-op regardless of recording phase',
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(prepSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => <AutoRecordState>[],
      verify: (_) {
        verifyNever(() => recorder.start(any()));
        verifyNever(() => recorder.stop());
      },
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'already recorded — repeated snapshots are a no-op, never re-stops',
      seed: () =>
          const AutoRecordState(recordingPhase: RecordingPhase.recorded),
      build: buildCubit,
      act: (cubit) {
        cubit.onTimerSnapshot(responseSnapshot);
        cubit.onTimerSnapshot(responseExpiredSnapshot);
      },
      wait: const Duration(milliseconds: 1),
      expect: () => <AutoRecordState>[],
      verify: (_) {
        verifyNever(() => recorder.start(any()));
        verifyNever(() => recorder.stop());
      },
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'resume-after-expiry: idle + response + remaining already zero on the first snapshot only starts, '
      'never stops in the same call',
      setUp: () => when(() => recorder.start(any())).thenAnswer((_) async {}),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(responseExpiredSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.recording),
      ],
      verify: (_) {
        verify(() => recorder.start(any())).called(1);
        verifyNever(() => recorder.stop());
      },
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'recording + response phase + non-expired remaining on a repeated mid-recording tick is a no-op '
      '(neither starts again nor stops)',
      seed: () =>
          const AutoRecordState(recordingPhase: RecordingPhase.recording),
      build: buildCubit,
      act: (cubit) {
        cubit.onTimerSnapshot(responseSnapshot);
        cubit.onTimerSnapshot(
          const TimerSnapshot(
            phase: TimerPhase.response,
            remaining: Duration(seconds: 10),
            currentOrderIndex: 1,
          ),
        );
      },
      wait: const Duration(milliseconds: 1),
      expect: () => <AutoRecordState>[],
      verify: (_) {
        verifyNever(() => recorder.start(any()));
        verifyNever(() => recorder.stop());
      },
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
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
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.recording),
      ],
      verify: (_) => verify(() => recorder.start(any())).called(1),
    );

    blocTest<AutoRecordCubit, AutoRecordState>(
      'two response-expired snapshots delivered back-to-back with no await between them while already '
      'recording still only stops recording once — guards against a synchronous re-entrant double-stop '
      'before the first stopRecording() await resolves (mirrors the double-start guard above for _stopInFlight)',
      setUp: () => when(
        () => recorder.stop(),
      ).thenAnswer((_) async => '/tmp/attempt-1_item-1.wav'),
      seed: () =>
          const AutoRecordState(recordingPhase: RecordingPhase.recording),
      build: buildCubit,
      act: (cubit) {
        // Deliberately no `await`/`wait` between these two synchronous calls
        // — onTimerSnapshot itself is synchronous (fires-and-forgets
        // stopRecording via unawaited), so both calls run to completion
        // before stopRecording's first `await` inside it has a chance to
        // flip state.recordingPhase away from recording.
        cubit.onTimerSnapshot(responseExpiredSnapshot);
        cubit.onTimerSnapshot(responseExpiredSnapshot);
      },
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AutoRecordState(recordingPhase: RecordingPhase.recorded),
      ],
      verify: (_) => verify(() => recorder.stop()).called(1),
    );
  });
}
