import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import 'data/repositories/scoring_review_repository_impl.dart';
import 'domain/repositories/scoring_review_repository.dart';
import 'domain/usecases/manage_scoring.dart';
import 'presentation/bloc/scoring_review_bloc.dart';

void setupScoringReviewModule() {
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<ScoringReviewRepository>(
    () => ScoringReviewRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<RequestScoring>(
    () => RequestScoring(repository: getIt<ScoringReviewRepository>()),
  );
  getIt.registerLazySingleton<LoadPendingReviews>(
    () => LoadPendingReviews(repository: getIt<ScoringReviewRepository>()),
  );
  getIt.registerLazySingleton<ApproveReview>(
    () => ApproveReview(repository: getIt<ScoringReviewRepository>()),
  );
  getIt.registerLazySingleton<PublishResults>(
    () => PublishResults(repository: getIt<ScoringReviewRepository>()),
  );
  getIt.registerFactory<ScoringReviewBloc>(
    () => ScoringReviewBloc(
      loadPendingReviews: getIt<LoadPendingReviews>(),
      approveReview: getIt<ApproveReview>(),
      requestScoring: getIt<RequestScoring>(),
      publishResults: getIt<PublishResults>(),
    ),
  );
}
