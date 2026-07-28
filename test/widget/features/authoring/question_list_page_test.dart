import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_state.dart';
import 'package:pte_app/features/authoring/presentation/bloc/question_list_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/question_list_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/question_list_state.dart';
import 'package:pte_app/features/authoring/presentation/pages/question_list_page.dart';

class _MockQuestionListBloc
    extends MockBloc<QuestionListEvent, QuestionListState>
    implements QuestionListBloc {}

class _MockCreateQuestionBloc
    extends MockBloc<CreateQuestionEvent, CreateQuestionState>
    implements CreateQuestionBloc {}

Question question() => Question(
  publicId: 'question-1',
  pteTaskType: PteTaskType.mcReadingSingle,
  section: 'READING',
  visibility: QuestionVisibility.private,
  tenantId: 'tenant-1',
  status: 'DRAFT',
  title: 'My question',
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
  final getIt = GetIt.instance;

  setUpAll(() {
    registerFallbackValue(const QuestionListRequested());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget subject(QuestionListState state, _MockQuestionListBloc bloc) {
    whenListen(
      bloc,
      const Stream<QuestionListState>.empty(),
      initialState: state,
    );
    return MaterialApp(
      home: QuestionListPage(
        key: ValueKey(state.runtimeType),
        questionListBloc: bloc,
      ),
    );
  }

  testWidgets('renders empty, failure, and loaded list states', (tester) async {
    final loadingBloc = _MockQuestionListBloc();
    await tester.pumpWidget(subject(const QuestionListLoading(), loadingBloc));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final emptyBloc = _MockQuestionListBloc();
    await tester.pumpWidget(subject(const QuestionListEmpty(), emptyBloc));
    expect(find.text(AppStrings.questionsEmpty), findsOneWidget);

    final failureBloc = _MockQuestionListBloc();
    await tester.pumpWidget(
      subject(QuestionListFailure(Exception('offline')), failureBloc),
    );
    expect(find.text(AppStrings.questionsLoadFailure), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);

    final loadedBloc = _MockQuestionListBloc();
    await tester.pumpWidget(
      subject(QuestionListLoaded([question()]), loadedBloc),
    );
    expect(find.text('My question'), findsOneWidget);
    expect(find.text('MC_READING_SINGLE'), findsOneWidget);
    expect(find.text('PRIVATE'), findsOneWidget);
    expect(find.text('DRAFT'), findsOneWidget);
  });

  testWidgets('backend create success pops and dispatches exactly one reload', (
    tester,
  ) async {
    final listBloc = _MockQuestionListBloc();
    whenListen(
      listBloc,
      const Stream<QuestionListState>.empty(),
      initialState: QuestionListLoaded([question()]),
    );
    final createBloc = _MockCreateQuestionBloc();
    final createStates = StreamController<CreateQuestionState>();
    whenListen(
      createBloc,
      createStates.stream,
      initialState: const CreateQuestionIdle(),
    );
    addTearDown(createStates.close);
    getIt.registerFactory<CreateQuestionBloc>(() => createBloc);
    await tester.pumpWidget(
      MaterialApp(home: QuestionListPage(questionListBloc: listBloc)),
    );

    await tester.tap(find.text(AppStrings.createQuestion));
    await tester.pumpAndSettle();
    expect(
      find.byType(BlocConsumer<CreateQuestionBloc, CreateQuestionState>),
      findsOneWidget,
    );

    createStates.add(CreateQuestionSuccess(question()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.createQuestionTitle), findsNothing);
    verify(() => listBloc.add(const QuestionListRequested())).called(2);
  });
}
