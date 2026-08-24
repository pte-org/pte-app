import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import 'data/repositories/scheduling_repository_impl.dart';
import 'domain/repositories/scheduling_repository.dart';
import 'domain/usecases/create_session.dart';
import 'domain/usecases/load_session.dart';
import 'domain/usecases/load_sessions.dart';
import 'domain/usecases/load_snapshot_options.dart';
import 'domain/usecases/manage_participants.dart';
import 'domain/usecases/update_session_composition.dart';
import 'domain/usecases/update_session_status.dart';
import 'presentation/bloc/session_create_bloc.dart';
import 'presentation/bloc/participant_command_bloc.dart';
import 'presentation/bloc/session_detail_bloc.dart';
import 'presentation/bloc/session_list_bloc.dart';

void setupSchedulingModule() {
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<SchedulingRepository>(
    () => SchedulingRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<LoadSessions>(
    () => LoadSessions(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerLazySingleton<LoadSession>(
    () => LoadSession(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerLazySingleton<CreateSession>(
    () => CreateSession(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerLazySingleton<LoadSnapshotOptions>(
    () => LoadSnapshotOptions(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerLazySingleton<UpdateSessionComposition>(
    () => UpdateSessionComposition(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerLazySingleton<OpenSession>(
    () => OpenSession(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerLazySingleton<CloseSession>(
    () => CloseSession(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerLazySingleton<EnrollStudent>(
    () => EnrollStudent(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerLazySingleton<AssignProctor>(
    () => AssignProctor(repository: getIt<SchedulingRepository>()),
  );
  getIt.registerFactory<EnrollmentBloc>(
    () => EnrollmentBloc(enrollStudent: getIt<EnrollStudent>()),
  );
  getIt.registerFactory<ProctorAssignmentBloc>(
    () => ProctorAssignmentBloc(assignProctor: getIt<AssignProctor>()),
  );
  getIt.registerFactory<SessionListBloc>(
    () => SessionListBloc(loadSessions: getIt<LoadSessions>()),
  );
  getIt.registerFactory<SessionCreateBloc>(
    () => SessionCreateBloc(createSession: getIt<CreateSession>()),
  );
  getIt.registerFactory<SessionDetailBloc>(
    () => SessionDetailBloc(
      loadSession: getIt<LoadSession>(),
      loadSnapshotOptions: getIt<LoadSnapshotOptions>(),
      updateComposition: getIt<UpdateSessionComposition>(),
      openSession: getIt<OpenSession>(),
      closeSession: getIt<CloseSession>(),
    ),
  );
}
