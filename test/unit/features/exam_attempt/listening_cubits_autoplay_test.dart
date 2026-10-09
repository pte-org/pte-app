import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/fill_blanks_listening_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_correct_summary_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/highlight_incorrect_words_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/mc_listening_multiple_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/mc_listening_single_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/select_missing_word_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/summarize_spoken_text_cubit.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/cubit/write_from_dictation_cubit.dart';

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
    when(() => player.hasFinishedPlaying).thenAnswer((_) => finishedController.stream);
    when(() => player.position).thenAnswer((_) => const Stream<Duration>.empty());
    when(() => player.duration).thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => player.close()).thenAnswer((_) async {});
  });

  tearDown(() => finishedController.close());

  const source = 'assets/audio/clip.mp3';

  final builders = <String, dynamic Function()>{
    'FillBlanksListeningCubit': () => FillBlanksListeningCubit(
      outboxDao: outboxDao,
      audioPlayerService: player,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      gapCount: 2,
      audioSource: source,
    ),
    'HighlightCorrectSummaryCubit': () => HighlightCorrectSummaryCubit(
      outboxDao: outboxDao,
      audioPlayerService: player,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      audioSource: source,
    ),
    'HighlightIncorrectWordsCubit': () => HighlightIncorrectWordsCubit(
      outboxDao: outboxDao,
      audioPlayerService: player,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      audioSource: source,
    ),
    'McListeningMultipleCubit': () => McListeningMultipleCubit(
      outboxDao: outboxDao,
      audioPlayerService: player,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      audioSource: source,
    ),
    'McListeningSingleCubit': () => McListeningSingleCubit(
      outboxDao: outboxDao,
      audioPlayerService: player,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      audioSource: source,
    ),
    'SelectMissingWordCubit': () => SelectMissingWordCubit(
      outboxDao: outboxDao,
      audioPlayerService: player,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      audioSource: source,
    ),
    'SummarizeSpokenTextCubit': () => SummarizeSpokenTextCubit(
      outboxDao: outboxDao,
      audioPlayerService: player,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      audioSource: source,
    ),
    'WriteFromDictationCubit': () => WriteFromDictationCubit(
      outboxDao: outboxDao,
      audioPlayerService: player,
      attemptPublicId: 'a',
      pinnedItemPublicId: 'i',
      audioSource: source,
    ),
  };

  builders.forEach((name, build) {
    test('$name: plays the audio source exactly once on construction', () async {
      final cubit = build() as dynamic;

      verify(() => player.play(source)).called(1);
      verifyNever(() => player.playUrl(any()));

      await cubit.close();
    });
  });
}
