import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/write_essay_cubit.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/cubit/write_essay_state.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/presentation/widgets/word_count_label.dart';

class _MockWriteEssayCubit extends MockCubit<WriteEssayState> implements WriteEssayCubit {}

void main() {
  late _MockWriteEssayCubit cubit;
  late StreamController<WriteEssayState> stateController;

  setUp(() {
    cubit = _MockWriteEssayCubit();
    stateController = StreamController<WriteEssayState>.broadcast();
    whenListen(cubit, stateController.stream, initialState: const WriteEssayState(draftText: 'hello', wordCount: 1));
  });

  tearDown(() async {
    await stateController.close();
  });

  Widget buildSubject({int? minWordCount, int? maxWordCount}) {
    return MaterialApp(
      home: BlocProvider<WriteEssayCubit>.value(
        value: cubit,
        child: Scaffold(body: WordCountLabel(minWordCount: minWordCount, maxWordCount: maxWordCount)),
      ),
    );
  }

  /// Mirrors `exam_app_bar_test.dart`'s widget-identity-comparison pattern
  /// exactly: `BlocSelector`'s `builder` closure only reruns when the
  /// selected slice (here `wordCount`) actually changes, so comparing
  /// `identical()` across pumps is a faithful proxy for "did this widget
  /// rebuild" (Step 13).
  Text textWidget(WidgetTester tester) => tester.widget<Text>(find.byType(Text));

  group('WordCountLabel — BlocSelector rebuild-avoidance (Step 13)', () {
    testWidgets(
      'an unrelated state change (draftText changes, wordCount slice unchanged) does not rebuild the label',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        final beforeText = textWidget(tester);
        expect(beforeText.data, '1 words');

        // Unrelated change: different draftText, but the same wordCount —
        // e.g. one word swapped for another single word.
        stateController.add(const WriteEssayState(draftText: 'howdy', wordCount: 1));
        await tester.pump();

        final afterText = textWidget(tester);
        expect(
          identical(beforeText, afterText),
          isTrue,
          reason: 'BlocSelector must not rebuild the label for a state change that leaves wordCount unchanged',
        );
        expect(afterText.data, '1 words');
      },
    );

    testWidgets('an actual wordCount change does rebuild the label', (tester) async {
      await tester.pumpWidget(buildSubject());
      final beforeText = textWidget(tester);

      stateController.add(const WriteEssayState(draftText: 'hello world', wordCount: 2));
      await tester.pump();

      final afterText = textWidget(tester);
      expect(
        identical(beforeText, afterText),
        isFalse,
        reason: 'BlocSelector must rebuild the label when the wordCount slice changes',
      );
      expect(afterText.data, '2 words');
    });

    testWidgets('renders the plain "N words" suffix with no bounds when min/max are not provided', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('1 words'), findsOneWidget);
    });

    testWidgets('renders both min and max bounds when both are provided', (tester) async {
      await tester.pumpWidget(buildSubject(minWordCount: 5, maxWordCount: 20));

      expect(find.text('1 words (min 5, max 20)'), findsOneWidget);
    });

    testWidgets('renders only the min bound when only minWordCount is provided', (tester) async {
      await tester.pumpWidget(buildSubject(minWordCount: 5));

      expect(find.text('1 words (min 5)'), findsOneWidget);
    });

    testWidgets(
      'being outside the min/max bounds does not render an error state — guidance only, never a hard gate',
      (tester) async {
        await tester.pumpWidget(buildSubject(minWordCount: 50, maxWordCount: 100));

        expect(find.text('1 words (min 50, max 100)'), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
