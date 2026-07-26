import 'package:get_it/get_it.dart';

import '_example_service.dart';

/// GetIt registration convention demonstrated by Phase 0 — every real
/// feature module (Phase 1 onward) follows this same `{feature}_module.dart`
/// shape: one `setup*Module()` function, called once from `main.dart`.
void setupExampleModule() {
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<ExampleService>(() => ExampleService());
}
