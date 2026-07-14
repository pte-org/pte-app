import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import 'timer_service.dart';

/// Registers the timer-layer singleton. Call once at app startup, after
/// `network_module.dart` (depends on [ApiClient] for sync-timer polling).
void registerTimerModule(GetIt getIt) {
  getIt.registerLazySingleton<TimerService>(
    () => TimerService(apiClient: getIt<ApiClient>()),
  );
}
