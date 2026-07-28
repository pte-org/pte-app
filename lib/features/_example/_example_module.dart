import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '_example_repository.dart';
import '_example_repository_impl.dart';

/// GetIt registration convention demonstrated by Phase 0 — every real
/// feature module (Phase 1 onward) follows this same `{feature}_module.dart`
/// shape: one `setup*Module()` function, called once from `main.dart`,
/// registering the abstract interface (never the concrete `Impl` type) with
/// its dependencies resolved via `getIt()` rather than constructed directly.
void setupExampleModule() {
  final getIt = GetIt.instance;

  if (!getIt.isRegistered<Logger>()) {
    getIt.registerLazySingleton<Logger>(() => Logger());
  }

  getIt.registerLazySingleton<ExampleRepository>(
    () => ExampleRepositoryImpl(logger: getIt()),
  );
}
