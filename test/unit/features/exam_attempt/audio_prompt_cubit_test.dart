import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_phase.dart';
import 'package:pte_app/features/exam_attempt/domain/timer_snapshot.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/audio_prompt_playback_state.dart';

class _MockAudioPromptRepository extends Mock implements AudioPromptRepository {}

class _MockAudioPlayerService extends Mock implements AudioPlayerService {}

// prepSeconds=12, preListenSeconds=3, preRecordSeconds=3 — mirrors
// RepeatSentenceScreen's real fixture, so "Playing" is elapsed in [3, 9).
TaskView _task({String? audioPromptRef = 'media-1'}) {
  return TaskView(
    pinnedItemPublicId: 'item-1',
    orderIndex: 1,
    totalTasks: 32,
    section: 'SPEAKING',
    taskType: 'REPEAT_SENTENCE',
    title: 'Repeat sentence',
    audioPromptRef: audioPromptRef,
    prepSeconds: 12,
    responseSeconds: 15,
  );
}

// elapsed = prepSeconds(12) - remaining(7) = 5 — inside the [3, 9) "Playing" window.
const _playingSnapshot = TimerSnapshot(phase: TimerPhase.prep, remaining: Duration(seconds: 7), currentOrderIndex: 1);
// elapsed = 12 - 10 = 2 — still "Beginning in" (pre-listen), before Playing starts.
const _beginningInSnapshot = TimerSnapshot(phase: TimerPhase.prep, remaining: Duration(seconds: 10), currentOrderIndex: 1);

void main() {
  late _MockAudioPromptRepository repository;
  late _MockAudioPlayerService player;
  late StreamController<Duration> positionController;
  late StreamController<Duration?> durationController;

  setUp(() {
    repository = _MockAudioPromptRepository();
    player = _MockAudioPlayerService();
    positionController = StreamController<Duration>.broadcast();
    durationController = StreamController<Duration?>.broadcast();
    when(() => player.position).thenAnswer((_) => positionController.stream);
    when(() => player.duration).thenAnswer((_) => durationController.stream);
    when(() => player.playUrl(any())).thenAnswer((_) async {});
    when(() => player.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    positionController.close();
    durationController.close();
  });

  AudioPromptCubit buildCubit({TaskView? task}) => AudioPromptCubit(
    repository: repository,
    player: player,
    task: task ?? _task(),
    attemptPublicId: 'attempt-1',
    preListenSeconds: 3,
    preRecordSeconds: 3,
  );

  group('AudioPromptCubit — trigger conditions', () {
    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'entering the Playing sub-stage calls playAudio with a generated play-request-id, then plays the '
      'resolved URL',
      setUp: () => when(
        () => repository.playAudio(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          playRequestId: any(named: 'playRequestId'),
        ),
      ).thenAnswer((_) async => 'https://example.com/audio.mp3'),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(_playingSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.loading),
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.playing),
      ],
      verify: (_) {
        verify(
          () => repository.playAudio(
            attemptPublicId: 'attempt-1',
            pinnedItemPublicId: 'item-1',
            playRequestId: any(named: 'playRequestId'),
          ),
        ).called(1);
        verify(() => player.playUrl('https://example.com/audio.mp3')).called(1);
      },
    );

    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'still in the Beginning-in sub-stage (before Playing starts) is a no-op',
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(_beginningInSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => <AudioPromptPlaybackState>[],
      verify: (_) {
        verifyNever(
          () => repository.playAudio(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            playRequestId: any(named: 'playRequestId'),
          ),
        );
      },
    );

    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'a task with no audioPromptRef never calls playAudio even when the Playing sub-stage is reached',
      build: () => buildCubit(task: _task(audioPromptRef: null)),
      act: (cubit) => cubit.onTimerSnapshot(_playingSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => <AudioPromptPlaybackState>[],
      verify: (_) {
        verifyNever(
          () => repository.playAudio(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            playRequestId: any(named: 'playRequestId'),
          ),
        );
      },
    );

    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'repeated snapshots within the same Playing sub-stage only trigger playAudio once — the fresh '
      'play-request-id is generated once per sub-stage entry (Phase 2 Step 3 decision), not per tick',
      setUp: () => when(
        () => repository.playAudio(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          playRequestId: any(named: 'playRequestId'),
        ),
      ).thenAnswer((_) async => 'https://example.com/audio.mp3'),
      build: buildCubit,
      act: (cubit) {
        cubit.onTimerSnapshot(_playingSnapshot);
        cubit.onTimerSnapshot(const TimerSnapshot(phase: TimerPhase.prep, remaining: Duration(seconds: 6), currentOrderIndex: 1));
      },
      wait: const Duration(milliseconds: 1),
      verify: (_) {
        verify(
          () => repository.playAudio(
            attemptPublicId: any(named: 'attemptPublicId'),
            pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
            playRequestId: any(named: 'playRequestId'),
          ),
        ).called(1);
      },
    );
  });

  group('AudioPromptCubit — error handling degrades gracefully, never crashes', () {
    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'ReplayLimitExceededException emits a clear error state with a specific message',
      setUp: () => when(
        () => repository.playAudio(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          playRequestId: any(named: 'playRequestId'),
        ),
      ).thenThrow(const ReplayLimitExceededException('REPLAY_LIMIT_EXCEEDED')),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(_playingSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.loading),
        predicate<AudioPromptPlaybackState>(
          (state) => state.phase == AudioPromptPlaybackPhase.error && state.errorMessage != null,
        ),
      ],
      verify: (_) => verifyNever(() => player.playUrl(any())),
    );

    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'AudioUrlExpiredException emits a clear error state with a specific message',
      setUp: () => when(
        () => repository.playAudio(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          playRequestId: any(named: 'playRequestId'),
        ),
      ).thenThrow(const AudioUrlExpiredException('AUDIO_URL_EXPIRED')),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(_playingSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.loading),
        predicate<AudioPromptPlaybackState>(
          (state) => state.phase == AudioPromptPlaybackPhase.error && state.errorMessage != null,
        ),
      ],
      verify: (_) => verifyNever(() => player.playUrl(any())),
    );

    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'an unrecognized failure (network, unreachable file) also degrades to the same non-crashing error '
      'state rather than rethrowing',
      setUp: () => when(
        () => repository.playAudio(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          playRequestId: any(named: 'playRequestId'),
        ),
      ).thenThrow(const NetworkException('Connection refused')),
      build: buildCubit,
      act: (cubit) => cubit.onTimerSnapshot(_playingSnapshot),
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.loading),
        predicate<AudioPromptPlaybackState>(
          (state) => state.phase == AudioPromptPlaybackPhase.error && state.errorMessage != null,
        ),
      ],
    );
  });

  group('AudioPromptCubit — progress tracks real player position/duration', () {
    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'progress stays 0.0 while duration is still unresolved, even once position starts advancing',
      setUp: () => when(
        () => repository.playAudio(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          playRequestId: any(named: 'playRequestId'),
        ),
      ).thenAnswer((_) async => 'https://example.com/audio.mp3'),
      build: buildCubit,
      act: (cubit) async {
        cubit.onTimerSnapshot(_playingSnapshot);
        await Future<void>.delayed(const Duration(milliseconds: 1));
        positionController.add(const Duration(seconds: 2));
      },
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.loading),
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.playing),
        // Duration is still null here — progress must not divide by it.
      ],
    );

    blocTest<AudioPromptCubit, AudioPromptPlaybackState>(
      'once duration is known, progress reflects position/duration clamped to [0.0, 1.0]',
      setUp: () => when(
        () => repository.playAudio(
          attemptPublicId: any(named: 'attemptPublicId'),
          pinnedItemPublicId: any(named: 'pinnedItemPublicId'),
          playRequestId: any(named: 'playRequestId'),
        ),
      ).thenAnswer((_) async => 'https://example.com/audio.mp3'),
      build: buildCubit,
      act: (cubit) async {
        cubit.onTimerSnapshot(_playingSnapshot);
        await Future<void>.delayed(const Duration(milliseconds: 1));
        durationController.add(const Duration(seconds: 10));
        positionController.add(const Duration(seconds: 5));
      },
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.loading),
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.playing),
        const AudioPromptPlaybackState(phase: AudioPromptPlaybackPhase.playing, progress: 0.5),
      ],
    );
  });

  group('AudioPromptCubit — close', () {
    test('close() closes the underlying player', () async {
      final cubit = buildCubit();
      await cubit.close();
      verify(() => player.close()).called(1);
    });
  });
}
