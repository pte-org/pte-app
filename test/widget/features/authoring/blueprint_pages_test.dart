import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/domain/blueprint_types.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_blueprint.dart';
import 'package:pte_app/features/authoring/domain/usecases/load_questions.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_builder_bloc.dart';
import 'package:pte_app/features/authoring/presentation/pages/blueprint_builder_page.dart';
import 'package:pte_app/features/authoring/presentation/pages/snapshot_detail_page.dart';

class _MockCreateBlueprint extends Mock implements CreateBlueprint {}

class _MockLoadQuestions extends Mock implements LoadQuestions {}

Question question(String id, String title, String section) => Question(
  publicId: id,
  pteTaskType: PteTaskType.mcReadingSingle,
  section: section,
  visibility: QuestionVisibility.private,
  tenantId: 'tenant-1',
  status: 'DRAFT',
  title: title,
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
  final getIt = GetIt.instance;
  tearDown(() => getIt.reset());
  setUpAll(
    () => registerFallbackValue(
      CreateBlueprintInput(name: 'fallback', items: const []),
    ),
  );

  testWidgets('builder submits selected questions in selection order', (
    tester,
  ) async {
    final load = _MockLoadQuestions();
    final create = _MockCreateBlueprint();
    when(load.call).thenAnswer(
      (_) async => [
        question('q-1', 'Reading one', 'READING'),
        question('q-2', 'Writing two', 'WRITING'),
      ],
    );
    when(() => create(any())).thenAnswer(
      (_) async => Blueprint(
        publicId: 'bp-1',
        name: 'Mock',
        tenantId: 'tenant-1',
        status: 'DRAFT',
        items: const [],
      ),
    );
    getIt.registerSingleton<LoadQuestions>(load);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => BlueprintBuilderBloc(createBlueprint: create),
          child: const BlueprintBuilderPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('blueprint-name')),
      'Mock',
    );
    await tester.tap(find.text('Writing two'));
    await tester.tap(find.text('Reading one'));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    final captured =
        verify(() => create(captureAny())).captured.single
            as CreateBlueprintInput;
    expect(captured.items.map((item) => item.questionPublicId), ['q-2', 'q-1']);
    expect(captured.items.map((item) => item.orderIndex), [0, 1]);
  });

  testWidgets('snapshot detail is read-only and renders frozen identity', (
    tester,
  ) async {
    final snapshot = ExamSnapshot(
      publicId: 'snap-1',
      name: 'Mock',
      version: 2,
      sourceBlueprintPublicId: 'bp-1',
      tenantId: 'tenant-1',
      items: const [
        SnapshotItem(
          orderIndex: 0,
          section: 'READING',
          taskType: PteTaskType.mcReadingSingle,
          title: 'Frozen question',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: SnapshotDetailPage(snapshot: snapshot)),
    );

    expect(find.text('Frozen question'), findsOneWidget);
    expect(find.text('${AppStrings.snapshotVersion} 2'), findsOneWidget);
    expect(find.text(AppStrings.edit), findsNothing);
    expect(find.text(AppStrings.delete), findsNothing);
  });
}
