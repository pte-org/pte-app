import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_read_aloud.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_write_essay.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_read_aloud_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_write_essay_bloc.dart';
import 'package:pte_app/features/authoring/presentation/pages/create_read_aloud_page.dart';
import 'package:pte_app/features/authoring/presentation/pages/create_write_essay_page.dart';

class _MockCreateReadAloud extends Mock implements CreateReadAloud {}

class _MockCreateWriteEssay extends Mock implements CreateWriteEssay {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CreateReadAloudInput(title: 'Read', promptText: 'Passage'),
    );
    registerFallbackValue(
      const CreateWriteEssayInput(
        title: 'Essay',
        promptText: 'Prompt',
        referenceAnswerText: 'Reference',
        minWordCount: 200,
        maxWordCount: 300,
      ),
    );
  });

  testWidgets('Read Aloud rejects blank fields before calling use case', (
    tester,
  ) async {
    final create = _MockCreateReadAloud();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CreateReadAloudBloc(createReadAloud: create),
          child: const CreateReadAloudPage(),
        ),
      ),
    );

    final submit = find.text(AppStrings.createQuestionSubmit);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text(AppStrings.authoringFieldRequired), findsNWidgets(2));
    verifyNever(() => create(any()));
  });

  testWidgets('Write Essay preserves fields when submission fails', (
    tester,
  ) async {
    final create = _MockCreateWriteEssay();
    when(() => create(any())).thenThrow(StateError('network'));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CreateWriteEssayBloc(createWriteEssay: create),
          child: const CreateWriteEssayPage(),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('essay-title')),
      'Essay title',
    );
    await tester.enterText(
      find.byKey(const ValueKey('essay-prompt')),
      'Essay prompt',
    );
    await tester.enterText(
      find.byKey(const ValueKey('essay-reference')),
      'Reference answer',
    );
    await tester.enterText(
      find.byKey(const ValueKey('essay-min-words')),
      '200',
    );
    await tester.enterText(
      find.byKey(const ValueKey('essay-max-words')),
      '300',
    );
    final essaySubmit = find.text(AppStrings.createQuestionSubmit);
    await tester.ensureVisible(essaySubmit);
    await tester.tap(essaySubmit);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.createQuestionFailure), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('essay-title')))
          .controller
          ?.text,
      'Essay title',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('essay-reference')))
          .controller
          ?.text,
      'Reference answer',
    );
  });
}
