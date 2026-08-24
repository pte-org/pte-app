import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_mc_reading_single.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_state.dart';

class _MockCreateMcReadingSingle extends Mock
    implements CreateMcReadingSingle {}

CreateMcReadingSingleInput validInput() => CreateMcReadingSingleInput(
  title: 'Question',
  promptText: 'Prompt',
  options: const [
    QuestionOptionInput(text: 'A', correct: true, orderIndex: 0),
    QuestionOptionInput(text: 'B', correct: false, orderIndex: 1),
  ],
);

Question createdQuestion() => Question(
  publicId: 'created-1',
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
  late _MockCreateMcReadingSingle createQuestion;

  setUpAll(() {
    registerFallbackValue(validInput());
  });

  setUp(() {
    createQuestion = _MockCreateMcReadingSingle();
    _pendingCreation = Completer<Question>();
  });

  blocTest<CreateQuestionBloc, CreateQuestionState>(
    'invalid input emits invalid without invoking use case',
    build: () => CreateQuestionBloc(createQuestion: createQuestion),
    act: (bloc) => bloc.add(
      CreateQuestionSubmitted(
        CreateMcReadingSingleInput(
          title: '',
          promptText: '',
          options: const [],
        ),
      ),
    ),
    expect: () => [isA<CreateQuestionInvalid>()],
    verify: (_) => verifyNever(() => createQuestion(any())),
  );

  blocTest<CreateQuestionBloc, CreateQuestionState>(
    'valid input emits one submitting-success cycle',
    setUp: () {
      when(
        () => createQuestion(any()),
      ).thenAnswer((_) async => createdQuestion());
    },
    build: () => CreateQuestionBloc(createQuestion: createQuestion),
    act: (bloc) => bloc.add(CreateQuestionSubmitted(validInput())),
    expect: () => [
      isA<CreateQuestionSubmitting>(),
      isA<CreateQuestionSuccess>().having(
        (state) => state.question.publicId,
        'id',
        'created-1',
      ),
    ],
    verify: (_) => verify(() => createQuestion(any())).called(1),
  );

  blocTest<CreateQuestionBloc, CreateQuestionState>(
    'repository failure emits failure after submitting',
    setUp: () {
      when(
        () => createQuestion(any()),
      ).thenAnswer((_) async => throw Exception('offline'));
    },
    build: () => CreateQuestionBloc(createQuestion: createQuestion),
    act: (bloc) => bloc.add(CreateQuestionSubmitted(validInput())),
    expect: () => [
      isA<CreateQuestionSubmitting>(),
      isA<CreateQuestionFailure>(),
    ],
  );

  blocTest<CreateQuestionBloc, CreateQuestionState>(
    'a second submit while in flight is ignored',
    setUp: () {
      when(
        () => createQuestion(any()),
      ).thenAnswer((_) => _pendingCreation.future);
    },
    build: () => CreateQuestionBloc(createQuestion: createQuestion),
    act: (bloc) async {
      bloc
        ..add(CreateQuestionSubmitted(validInput()))
        ..add(CreateQuestionSubmitted(validInput()));
      await Future<void>.delayed(Duration.zero);
      _pendingCreation.complete(createdQuestion());
    },
    expect: () => [
      isA<CreateQuestionSubmitting>(),
      isA<CreateQuestionSuccess>(),
    ],
    verify: (_) => verify(() => createQuestion(any())).called(1),
  );
}

late Completer<Question> _pendingCreation;
