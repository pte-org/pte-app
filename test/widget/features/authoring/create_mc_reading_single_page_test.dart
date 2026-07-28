import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_state.dart';
import 'package:pte_app/features/authoring/presentation/pages/create_mc_reading_single_page.dart';

class _MockCreateQuestionBloc
    extends MockBloc<CreateQuestionEvent, CreateQuestionState>
    implements CreateQuestionBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      CreateQuestionSubmitted(
        CreateMcReadingSingleInput(
          title: '',
          promptText: '',
          options: const [],
        ),
      ),
    );
  });

  Future<_MockCreateQuestionBloc> pumpSubject(
    WidgetTester tester, {
    CreateQuestionState initialState = const CreateQuestionIdle(),
    Stream<CreateQuestionState> stream = const Stream.empty(),
  }) async {
    final bloc = _MockCreateQuestionBloc();
    whenListen(bloc, stream, initialState: initialState);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CreateQuestionBloc>.value(
          value: bloc,
          child: const CreateMcReadingSinglePage(),
        ),
      ),
    );
    return bloc;
  }

  testWidgets('adds/removes options and submits one selected correct answer', (
    tester,
  ) async {
    final bloc = await pumpSubject(tester);

    expect(find.byType(TextFormField), findsNWidgets(4));
    await tester.tap(find.widgetWithText(OutlinedButton, AppStrings.addOption));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(5));
    await tester.tap(find.byIcon(Icons.remove_circle_outline).last);
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(4));

    await tester.enterText(find.byType(TextFormField).at(0), 'Title');
    await tester.enterText(find.byType(TextFormField).at(1), 'Prompt');
    await tester.enterText(find.byType(TextFormField).at(2), 'A');
    await tester.enterText(find.byType(TextFormField).at(3), 'B');
    await tester.tap(find.byType(Radio<int>).first);
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.createQuestionSubmit),
    );

    final captured =
        verify(
              () => bloc.add(captureAny(that: isA<CreateQuestionSubmitted>())),
            ).captured.single
            as CreateQuestionSubmitted;
    expect(captured.input.options.map((option) => option.orderIndex), [0, 1]);
    expect(captured.input.options.where((option) => option.correct).length, 1);
  });

  for (final scenario
      in <({String name, int selected, int removed, int? expected})>[
        (name: 'before', selected: 2, removed: 0, expected: 1),
        (name: 'selected', selected: 2, removed: 2, expected: null),
        (name: 'after', selected: 0, removed: 2, expected: 0),
      ]) {
    testWidgets(
      'removing an option ${scenario.name} the correct choice keeps selection consistent',
      (tester) async {
        final bloc = await pumpSubject(tester);
        await tester.tap(
          find.widgetWithText(OutlinedButton, AppStrings.addOption),
        );
        await tester.pump();
        await tester.tap(find.byType(Radio<int>).at(scenario.selected));
        await tester.pump();
        await tester.tap(
          find.byIcon(Icons.remove_circle_outline).at(scenario.removed),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextFormField).at(0), 'Title');
        await tester.enterText(find.byType(TextFormField).at(1), 'Prompt');
        await tester.enterText(find.byType(TextFormField).at(2), 'A');
        await tester.enterText(find.byType(TextFormField).at(3), 'B');
        await tester.tap(
          find.widgetWithText(ElevatedButton, AppStrings.createQuestionSubmit),
        );

        final event =
            verify(
                  () => bloc.add(
                    captureAny(that: isA<CreateQuestionSubmitted>()),
                  ),
                ).captured.single
                as CreateQuestionSubmitted;
        final correctIndexes = event.input.options
            .where((option) => option.correct)
            .map((option) => option.orderIndex)
            .toList();
        expect(
          correctIndexes,
          scenario.expected == null ? isEmpty : [scenario.expected],
        );
      },
    );
  }

  testWidgets('submitting state disables the action and shows progress', (
    tester,
  ) async {
    await pumpSubject(tester, initialState: const CreateQuestionSubmitting());

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('failure feedback preserves every entered form value', (
    tester,
  ) async {
    final states = StreamController<CreateQuestionState>();
    addTearDown(states.close);
    await pumpSubject(tester, stream: states.stream);
    await tester.enterText(find.byType(TextFormField).at(0), 'Saved title');
    await tester.enterText(find.byType(TextFormField).at(1), 'Saved prompt');
    await tester.enterText(find.byType(TextFormField).at(2), 'Saved A');
    await tester.enterText(find.byType(TextFormField).at(3), 'Saved B');

    states.add(CreateQuestionFailure(Exception('offline')));
    await tester.pump();

    expect(find.text(AppStrings.createQuestionFailure), findsOneWidget);
    expect(find.text('Saved title'), findsOneWidget);
    expect(find.text('Saved prompt'), findsOneWidget);
    expect(find.text('Saved A'), findsOneWidget);
    expect(find.text('Saved B'), findsOneWidget);
  });
}
