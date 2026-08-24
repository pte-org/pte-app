import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import 'data/repositories/host_audit_repository_impl.dart';
import 'domain/repositories/host_audit_repository.dart';
import 'domain/usecases/load_host_audit.dart';
import 'presentation/bloc/notification_audit_bloc.dart';
import 'presentation/bloc/violation_audit_bloc.dart';

void setupHostAuditModule() {
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<HostAuditRepository>(
    () => HostAuditRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<LoadNotifications>(
    () => LoadNotifications(repository: getIt<HostAuditRepository>()),
  );
  getIt.registerLazySingleton<LoadViolations>(
    () => LoadViolations(repository: getIt<HostAuditRepository>()),
  );
  getIt.registerFactory<NotificationAuditBloc>(
    () => NotificationAuditBloc(loadNotifications: getIt<LoadNotifications>()),
  );
  getIt.registerFactory<ViolationAuditBloc>(
    () => ViolationAuditBloc(loadViolations: getIt<LoadViolations>()),
  );
}
