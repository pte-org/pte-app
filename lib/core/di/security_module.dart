import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/platform/clipboard_monitor_channel.dart';
import 'package:pte_app/core/platform/process_manager_channel.dart';
import 'package:pte_app/core/platform/shortcut_interceptor_channel.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/violation_reporter.dart';
import 'package:pte_app/core/storage/dao/local_violation_dao.dart';

/// GetIt registration for lockdown pipeline. Phase 4 wires the
/// `ViolationReporter` and `LockdownService` into the existing DI
/// container — every dependency (ApiClient, NativeChannel wrappers,
/// AppDatabase DAOs) is already registered elsewhere in the app.
///
/// Caller responsibility (in main.dart):
///   - `setupSecurityModule()` registers the lazy singletons.
///   - `await getIt<LockdownService>().initialize()` is called once
///     during bootstrap so the forbidden-apps JSON is loaded before
///     the first attempt to activate.
void setupSecurityModule() {
  final getIt = GetIt.instance;

  // Platform channels — cheap to construct, so eager singletons are
  // fine. None of them holds native resources beyond what the OS
  // allocates on first method call.
  getIt.registerLazySingleton<WindowManagerChannel>(
    () => const WindowManagerChannel(),
  );
  getIt.registerLazySingleton<ProcessManagerChannel>(
    () => const ProcessManagerChannel(),
  );
  getIt.registerLazySingleton<ClipboardMonitorChannel>(
    () => const ClipboardMonitorChannel(),
  );
  getIt.registerLazySingleton<ShortcutInterceptorChannel>(
    () => const ShortcutInterceptorChannel(),
  );

  getIt.registerLazySingleton<ViolationReporter>(
    () => ViolationReporter(
      apiClient: getIt<ApiClient>(),
      localDao: getIt<LocalViolationDao>(),
      // Not getIt<Logger>() — this codebase never registers a shared
      // Logger in GetIt (every other class that takes one, e.g.
      // TimerService/AttemptMapper, defaults an optional constructor
      // param to Logger() itself). getIt<Logger>() only ever resolved
      // by accident via lib/features/_example/_example_module.dart,
      // which main.dart never actually calls — this threw
      // "Logger is not registered inside GetIt" on real app startup.
      logger: Logger(),
    ),
  );

  getIt.registerLazySingleton<LockdownService>(
    () => LockdownService(
      windowManager: getIt<WindowManagerChannel>(),
      processManager: getIt<ProcessManagerChannel>(),
      clipboard: getIt<ClipboardMonitorChannel>(),
      shortcuts: getIt<ShortcutInterceptorChannel>(),
      violationReporter: getIt<ViolationReporter>(),
      logger: Logger(),
    ),
  );
}
