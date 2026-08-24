import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/domain/usecases/load_questions.dart';
import 'package:pte_app/features/authoring/presentation/bloc/question_list_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/question_list_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/question_list_state.dart';

class _MockLoadQuestions extends Mock implements LoadQuestions {}

Question question([String publicId = 'question-1']) => Question(
  publicId: publicId,
  pteTaskType: PteTaskType.mcReadingSingle,
  section: 'READING',
  visibility: QuestionVisibility.private,
  tenantId: 'tenant-1',
  status: 'DRAFT',
  title: 'Question',
  promptText: 'Prompt',
  audioPromptRef: null,
  imagePromptRef: null,
  referenceAnswerText: null,
  correctAnswerText: null,
  minWordCount: null,
  maxWordCount: null,
  options: const [],
  skills: const ['READING'],
);

void main() {
  late _MockLoadQuestions loadQuestions;

  setUp(() {
    loadQuestions = _MockLoadQuestions();
    _firstLoad = Completer<List<Question>>();
    _reload = Completer<List<Question>>();
  });

  blocTest<QuestionListBloc, QuestionListState>(
    'request emits loading then empty',
    setUp: () => when(() => loadQuestions()).thenAnswer((_) async => []),
    build: () => QuestionListBloc(loadQuestions: loadQuestions),
    act: (bloc) => bloc.add(const QuestionListRequested()),
    expect: () => [isA<QuestionListLoading>(), isA<QuestionListEmpty>()],
  );

  blocTest<QuestionListBloc, QuestionListState>(
    'request emits loading then loaded',
    setUp: () =>
        when(() => loadQuestions()).thenAnswer((_) async => [question()]),
    build: () => QuestionListBloc(loadQuestions: loadQuestions),
    act: (bloc) => bloc.add(const QuestionListRequested()),
    expect: () => [
      isA<QuestionListLoading>(),
      isA<QuestionListLoaded>().having(
        (state) => state.questions.length,
        'count',
        1,
      ),
    ],
  );

  blocTest<QuestionListBloc, QuestionListState>(
    'retry uses the same authoritative load cycle after failure',
    setUp: () {
      when(
        () => loadQuestions(),
      ).thenAnswer((_) async => throw Exception('offline'));
    },
    build: () => QuestionListBloc(loadQuestions: loadQuestions),
    act: (bloc) => bloc.add(const QuestionListRetryRequested()),
    expect: () => [isA<QuestionListLoading>(), isA<QuestionListFailure>()],
  );

  blocTest<QuestionListBloc, QuestionListState>(
    'a stale request cannot overwrite a newer authoritative reload',
    setUp: () {
      var callCount = 0;
      when(() => loadQuestions()).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? _firstLoad.future : _reload.future;
      });
    },
    build: () => QuestionListBloc(loadQuestions: loadQuestions),
    act: (bloc) async {
      bloc.add(const QuestionListRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuestionListRetryRequested());
      await Future<void>.delayed(Duration.zero);
      _reload.complete([question('new')]);
      await Future<void>.delayed(Duration.zero);
      _firstLoad.complete([question('stale')]);
    },
    expect: () => [
      isA<QuestionListLoading>(),
      isA<QuestionListLoaded>().having(
        (state) => state.questions.single.publicId,
        'latest id',
        'new',
      ),
    ],
  );
}

late Completer<List<Question>> _firstLoad;
late Completer<List<Question>> _reload;
