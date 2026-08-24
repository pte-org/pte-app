import 'package:get_it/get_it.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/features/report/data/repositories/report_repository_impl.dart';
import 'package:pte_app/features/report/domain/repositories/report_repository.dart';

void setupReportModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<ReportRepository>(() => ReportRepositoryImpl(apiClient: getIt<ApiClient>()));
}
