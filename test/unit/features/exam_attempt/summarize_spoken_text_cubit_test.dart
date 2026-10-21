import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/summarize_spoken_text_cubit.dart';

class _MockAnswerOutboxDao extends Mock implements AnswerOutboxDao {}

class _MockAudioPlayerService extends Mock implements AudioPlayerService {}

void main() {
  late _MockAnswerOutboxDao outboxDao;
  late _MockAudioPlayerService player;
  late StreamController<bool> finishedController;

  setUp(() {
    outboxDao = _MockAnswerOutboxDao();
    player = _MockAudioPlayerService();
    finishedController = StreamController<bool>.broadcast();
    when(() => player.play(any())).thenAnswer((_) async {});
    when(
      () => player.hasFinishedPlaying,
    ).thenAnswer((_) => finishedController.stream);
    when(
      () => player.position,
    ).thenAnswer((_) => const Stream<Duration>.empty());
    when(
      () => player.duration,
    ).thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => player.close()).thenAnswer((_) async {});
  });

  tearDown(() => finishedController.close());

  SummarizeSpokenTextCubit build() => SummarizeSpokenTextCubit(
    outboxDao: outboxDao,
    audioPlayerService: player,
    attemptPublicId: 'a',
    pinnedItemPublicId: 'i',
    audioSource: 'assets/audio/clip.mp3',
  );

  test('starts with neither finished nor failed playback', () async {
    final cubit = build();

    expect(cubit.state.hasFinishedPlaying, isFalse);
    expect(cubit.state.playbackFailed, isFalse);
    await cubit.close();
  });

  test('marks playback finished when the audio completes', () async {
    final cubit = build();

    finishedController.add(true);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.hasFinishedPlaying, isTrue);
    expect(cubit.state.playbackFailed, isFalse);
    await cubit.close();
  });

  test('marks playback failed when the audio cannot be played', () async {
    when(() => player.play(any())).thenThrow(Exception('404'));
    final cubit = build();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.playbackFailed, isTrue);
    expect(cubit.state.hasFinishedPlaying, isFalse);
    await cubit.close();
  });
}
