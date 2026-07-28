import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/authoring/domain/authoring_types.dart';
import 'package:pte_app/features/authoring/domain/repositories/authoring_repository.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_mc_reading_single.dart';

class _MockAuthoringRepository extends Mock implements AuthoringRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      CreateMcReadingSingleInput(
        title: 'fallback',
        promptText: 'fallback',
        options: const [],
      ),
    );
  });

  test('invalid input is rejected before repository delegation', () async {
    final repository = _MockAuthoringRepository();
    final useCase = CreateMcReadingSingle(repository: repository);
    final invalid = CreateMcReadingSingleInput(
      title: '',
      promptText: 'Prompt',
      options: const [],
    );

    expect(
      () => useCase(invalid),
      throwsA(isA<AuthoringValidationException>()),
    );
    verifyNever(() => repository.createMcReadingSingle(any()));
  });
}
