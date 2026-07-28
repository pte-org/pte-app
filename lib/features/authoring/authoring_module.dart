import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import 'data/repositories/authoring_repository_impl.dart';
import 'domain/repositories/authoring_repository.dart';
import 'domain/usecases/create_blueprint.dart';
import 'domain/usecases/create_mc_reading_single.dart';
import 'domain/usecases/create_read_aloud.dart';
import 'domain/usecases/create_write_essay.dart';
import 'domain/usecases/load_questions.dart';
import 'domain/usecases/load_blueprint.dart';
import 'domain/usecases/load_blueprints.dart';
import 'domain/usecases/load_snapshot.dart';
import 'domain/usecases/publish_blueprint.dart';
import 'presentation/bloc/blueprint_builder_bloc.dart';
import 'presentation/bloc/blueprint_detail_bloc.dart';
import 'presentation/bloc/blueprint_list_bloc.dart';
import 'presentation/bloc/create_read_aloud_bloc.dart';
import 'presentation/bloc/create_question_bloc.dart';
import 'presentation/bloc/create_write_essay_bloc.dart';
import 'presentation/bloc/question_list_bloc.dart';

void setupAuthoringModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<AuthoringRepository>(
    () => AuthoringRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<LoadQuestions>(
    () => LoadQuestions(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerLazySingleton<CreateMcReadingSingle>(
    () => CreateMcReadingSingle(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerLazySingleton<CreateReadAloud>(
    () => CreateReadAloud(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerLazySingleton<CreateWriteEssay>(
    () => CreateWriteEssay(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerLazySingleton<LoadBlueprints>(
    () => LoadBlueprints(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerLazySingleton<LoadBlueprint>(
    () => LoadBlueprint(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerLazySingleton<CreateBlueprint>(
    () => CreateBlueprint(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerLazySingleton<PublishBlueprint>(
    () => PublishBlueprint(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerLazySingleton<LoadSnapshot>(
    () => LoadSnapshot(repository: getIt<AuthoringRepository>()),
  );
  getIt.registerFactory<QuestionListBloc>(
    () => QuestionListBloc(loadQuestions: getIt<LoadQuestions>()),
  );
  getIt.registerFactory<CreateQuestionBloc>(
    () => CreateQuestionBloc(createQuestion: getIt<CreateMcReadingSingle>()),
  );
  getIt.registerFactory<CreateReadAloudBloc>(
    () => CreateReadAloudBloc(createReadAloud: getIt<CreateReadAloud>()),
  );
  getIt.registerFactory<CreateWriteEssayBloc>(
    () => CreateWriteEssayBloc(createWriteEssay: getIt<CreateWriteEssay>()),
  );
  getIt.registerFactory<BlueprintListBloc>(
    () => BlueprintListBloc(loadBlueprints: getIt<LoadBlueprints>()),
  );
  getIt.registerFactory<BlueprintBuilderBloc>(
    () => BlueprintBuilderBloc(createBlueprint: getIt<CreateBlueprint>()),
  );
  getIt.registerFactory<BlueprintDetailBloc>(
    () => BlueprintDetailBloc(
      loadBlueprint: getIt<LoadBlueprint>(),
      publishBlueprint: getIt<PublishBlueprint>(),
    ),
  );
}
