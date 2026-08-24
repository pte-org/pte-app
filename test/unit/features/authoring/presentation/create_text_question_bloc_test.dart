import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_read_aloud.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_write_essay.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_read_aloud_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_read_aloud_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_read_aloud_state.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_write_essay_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_write_essay_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_write_essay_state.dart';

class _MockCreateReadAloud extends Mock implements CreateReadAloud {}

class _MockCreateWriteEssay extends Mock implements CreateWriteEssay {}

Question question(PteTaskType type) => Question(
  publicId: 'question-1',
  pteTaskType: type,
  section: type == PteTaskType.readAloud ? 'SPEAKING' : 'WRITING',
  visibility: QuestionVisibility.private,
  tenantId: 'tenant-1',
  status: 'DRAFT',
  title: 'Title',
  promptText: 'Prompt',
  audioPromptRef: null,
  imagePromptRef: null,
  referenceAnswerText: null,
  correctAnswerText: null,
  minWordCount: null,
  maxWordCount: null,
  options: const [],
  skills: const [],
);

void main() {
  const readInput = CreateReadAloudInput(title: 'Read', promptText: 'Passage');
  const essayInput = CreateWriteEssayInput(
    title: 'Essay',
    promptText: 'Discuss',
    referenceAnswerText: 'Reference',
    minWordCount: 200,
    maxWordCount: 300,
  );

  setUpAll(() {
    registerFallbackValue(readInput);
    registerFallbackValue(essayInput);
  });

  group('CreateReadAloudBloc', () {
    late _MockCreateReadAloud create;

    setUp(() => create = _MockCreateReadAloud());

    blocTest<CreateReadAloudBloc, CreateReadAloudState>(
      'emits invalid without calling use case',
      build: () => CreateReadAloudBloc(createReadAloud: create),
      act: (bloc) => bloc.add(
        const ReadAloudSubmitted(
          CreateReadAloudInput(title: '', promptText: 'Prompt'),
        ),
      ),
      expect: () => [isA<CreateReadAloudInvalid>()],
      verify: (_) => verifyNever(() => create(any())),
    );

    blocTest<CreateReadAloudBloc, CreateReadAloudState>(
      'emits submitting then success',
      setUp: () => when(
        () => create(any()),
      ).thenAnswer((_) async => question(PteTaskType.readAloud)),
      build: () => CreateReadAloudBloc(createReadAloud: create),
      act: (bloc) => bloc.add(const ReadAloudSubmitted(readInput)),
      expect: () => [
        isA<CreateReadAloudSubmitting>(),
        isA<CreateReadAloudSuccess>(),
      ],
    );

    test('ignores a duplicate submit while the first is pending', () async {
      final pending = Completer<Question>();
      when(() => create(any())).thenAnswer((_) => pending.future);
      final bloc = CreateReadAloudBloc(createReadAloud: create);

      bloc
        ..add(const ReadAloudSubmitted(readInput))
        ..add(const ReadAloudSubmitted(readInput));
      await Future<void>.delayed(Duration.zero);

      verify(() => create(any())).called(1);
      pending.complete(question(PteTaskType.readAloud));
      await bloc.close();
    });
  });

  group('CreateWriteEssayBloc', () {
    late _MockCreateWriteEssay create;

    setUp(() => create = _MockCreateWriteEssay());

    blocTest<CreateWriteEssayBloc, CreateWriteEssayState>(
      'emits invalid for reversed bounds',
      build: () => CreateWriteEssayBloc(createWriteEssay: create),
      act: (bloc) => bloc.add(
        const WriteEssaySubmitted(
          CreateWriteEssayInput(
            title: 'Essay',
            promptText: 'Prompt',
            referenceAnswerText: 'Reference',
            minWordCount: 301,
            maxWordCount: 300,
          ),
        ),
      ),
      expect: () => [isA<CreateWriteEssayInvalid>()],
      verify: (_) => verifyNever(() => create(any())),
    );

    blocTest<CreateWriteEssayBloc, CreateWriteEssayState>(
      'emits submitting then failure and can retry',
      setUp: () {
        var calls = 0;
        when(() => create(any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) {
            throw StateError('network');
          }
          return question(PteTaskType.writeEssay);
        });
      },
      build: () => CreateWriteEssayBloc(createWriteEssay: create),
      act: (bloc) async {
        bloc.add(const WriteEssaySubmitted(essayInput));
        await bloc.stream.firstWhere(
          (state) => state is CreateWriteEssayFailure,
        );
        bloc.add(const WriteEssaySubmitted(essayInput));
      },
      expect: () => [
        isA<CreateWriteEssaySubmitting>(),
        isA<CreateWriteEssayFailure>(),
        isA<CreateWriteEssaySubmitting>(),
        isA<CreateWriteEssaySuccess>(),
      ],
    );
  });
}
