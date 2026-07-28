import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/authoring/authoring_module.dart';
import 'package:pte_app/features/authoring/domain/repositories/authoring_repository.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_mc_reading_single.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_read_aloud.dart';
import 'package:pte_app/features/authoring/domain/usecases/create_write_essay.dart';
import 'package:pte_app/features/authoring/domain/usecases/load_questions.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_read_aloud_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_question_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/create_write_essay_bloc.dart';
import 'package:pte_app/features/authoring/presentation/bloc/question_list_bloc.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  final getIt = GetIt.instance;

  tearDown(() async {
    await getIt.reset();
  });

  test('module keeps data/use cases singleton and creates fresh BLoCs', () {
    getIt.registerSingleton<ApiClient>(_MockApiClient());

    setupAuthoringModule();

    expect(
      identical(getIt<AuthoringRepository>(), getIt<AuthoringRepository>()),
      isTrue,
    );
    expect(identical(getIt<LoadQuestions>(), getIt<LoadQuestions>()), isTrue);
    expect(
      identical(getIt<CreateMcReadingSingle>(), getIt<CreateMcReadingSingle>()),
      isTrue,
    );
    expect(
      identical(getIt<CreateReadAloud>(), getIt<CreateReadAloud>()),
      isTrue,
    );
    expect(
      identical(getIt<CreateWriteEssay>(), getIt<CreateWriteEssay>()),
      isTrue,
    );
    expect(
      identical(getIt<QuestionListBloc>(), getIt<QuestionListBloc>()),
      isFalse,
    );
    expect(
      identical(getIt<CreateQuestionBloc>(), getIt<CreateQuestionBloc>()),
      isFalse,
    );
    expect(
      identical(getIt<CreateReadAloudBloc>(), getIt<CreateReadAloudBloc>()),
      isFalse,
    );
    expect(
      identical(getIt<CreateWriteEssayBloc>(), getIt<CreateWriteEssayBloc>()),
      isFalse,
    );
  });
}
