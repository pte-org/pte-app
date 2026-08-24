import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/authoring/domain/blueprint_types.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_blueprint.dart';
import 'package:pte_app/features/authoring/domain/usecases/load_blueprint.dart';
import 'package:pte_app/features/authoring/domain/usecases/load_blueprints.dart';
import 'package:pte_app/features/authoring/domain/usecases/publish_blueprint.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_builder_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_builder_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_builder_state.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_detail_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_detail_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_detail_state.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_list_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_list_event.dart';
import 'package:pte_app/features/authoring/presentation/bloc/blueprint_list_state.dart';

class _MockLoadBlueprints extends Mock implements LoadBlueprints {}

class _MockCreateBlueprint extends Mock implements CreateBlueprint {}

class _MockLoadBlueprint extends Mock implements LoadBlueprint {}

class _MockPublishBlueprint extends Mock implements PublishBlueprint {}

final blueprint = Blueprint(
  publicId: 'bp-1',
  name: 'Exam',
  tenantId: 'tenant-1',
  status: 'DRAFT',
  items: const [
    BlueprintItem(questionPublicId: 'q-1', section: 'READING', orderIndex: 0),
  ],
);
final snapshot = ExamSnapshot(
  publicId: 'snap-1',
  name: 'Exam',
  version: 1,
  sourceBlueprintPublicId: 'bp-1',
  tenantId: 'tenant-1',
  items: const [],
);
final validInput = CreateBlueprintInput(
  name: 'Exam',
  items: const [
    BlueprintItemInput(
      questionPublicId: 'q-1',
      section: 'READING',
      orderIndex: 0,
    ),
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(validInput));

  blocTest<BlueprintListBloc, BlueprintListState>(
    'loads blueprints into loaded state',
    setUp: () {
      final load = _MockLoadBlueprints();
      when(load.call).thenAnswer((_) async => [blueprint]);
      _loadBlueprints = load;
    },
    build: () => BlueprintListBloc(loadBlueprints: _loadBlueprints),
    act: (bloc) => bloc.add(const BlueprintListRequested()),
    expect: () => [isA<BlueprintListLoading>(), isA<BlueprintListLoaded>()],
  );

  blocTest<BlueprintBuilderBloc, BlueprintBuilderState>(
    'rejects empty composition before create use case',
    build: () {
      _createBlueprint = _MockCreateBlueprint();
      return BlueprintBuilderBloc(createBlueprint: _createBlueprint);
    },
    act: (bloc) => bloc.add(
      BlueprintSubmitted(CreateBlueprintInput(name: 'Exam', items: const [])),
    ),
    expect: () => [isA<BlueprintBuilderInvalid>()],
    verify: (_) => verifyNever(() => _createBlueprint(any())),
  );

  blocTest<BlueprintBuilderBloc, BlueprintBuilderState>(
    'emits submitting then success',
    setUp: () {
      _createBlueprint = _MockCreateBlueprint();
      when(() => _createBlueprint(any())).thenAnswer((_) async => blueprint);
    },
    build: () => BlueprintBuilderBloc(createBlueprint: _createBlueprint),
    act: (bloc) => bloc.add(BlueprintSubmitted(validInput)),
    expect: () => [
      isA<BlueprintBuilderSubmitting>(),
      isA<BlueprintBuilderSuccess>(),
    ],
  );

  test(
    'detail publish is single-flight and returns immutable snapshot',
    () async {
      final load = _MockLoadBlueprint();
      final publish = _MockPublishBlueprint();
      final pending = Completer<ExamSnapshot>();
      when(() => load('bp-1')).thenAnswer((_) async => blueprint);
      when(() => publish('bp-1')).thenAnswer((_) => pending.future);
      final bloc = BlueprintDetailBloc(
        loadBlueprint: load,
        publishBlueprint: publish,
      );

      bloc.add(const BlueprintDetailRequested('bp-1'));
      await bloc.stream.firstWhere((state) => state is BlueprintDetailReady);
      bloc
        ..add(const BlueprintPublishRequested())
        ..add(const BlueprintPublishRequested());
      await Future<void>.delayed(Duration.zero);

      verify(() => publish('bp-1')).called(1);
      pending.complete(snapshot);
      expect(
        await bloc.stream.firstWhere((state) => state is BlueprintPublished),
        isA<BlueprintPublished>(),
      );
      await bloc.close();
    },
  );
}

late LoadBlueprints _loadBlueprints;
late CreateBlueprint _createBlueprint;
