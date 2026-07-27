import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import 'data/repositories/report_repository_impl.dart';
import 'domain/repositories/report_repository.dart';

void setupReportModule() {
  final getIt = GetIt.instance;

  getIt.registerLazySingleton<ReportRepository>(() => ReportRepositoryImpl(apiClient: getIt<ApiClient>()));
}
