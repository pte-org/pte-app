import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import 'data/repositories/authoring_repository_impl.dart';
import 'domain/repositories/authoring_repository.dart';
import 'domain/usecases/create_mc_reading_single.dart';
import 'domain/usecases/load_questions.dart';
import 'presentation/bloc/create_question_bloc.dart';
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
  getIt.registerFactory<QuestionListBloc>(
    () => QuestionListBloc(loadQuestions: getIt<LoadQuestions>()),
  );
  getIt.registerFactory<CreateQuestionBloc>(
    () => CreateQuestionBloc(createQuestion: getIt<CreateMcReadingSingle>()),
  );
}
