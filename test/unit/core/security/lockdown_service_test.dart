import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/platform/clipboard_monitor_channel.dart';
import 'package:pte_app/core/platform/lockdown_exception.dart';
import 'package:pte_app/core/platform/process_manager_channel.dart';
import 'package:pte_app/core/platform/shortcut_interceptor_channel.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';
import 'package:pte_app/core/security/config/forbidden_apps_config.dart';
import 'package:pte_app/core/security/lockdown_mode.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/security/violation_reporter.dart';

class _MockWindowManagerChannel extends Mock
    implements WindowManagerChannel {}

class _MockProcessManagerChannel extends Mock
    implements ProcessManagerChannel {}

class _MockClipboardMonitorChannel extends Mock
    implements ClipboardMonitorChannel {}

class _MockShortcutInterceptorChannel extends Mock
    implements ShortcutInterceptorChannel {}

class _MockViolationReporter extends Mock implements ViolationReporter {}

class _PlatformLogger extends Logger {
  _PlatformLogger() : super();
  @override
  void i(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {}
  @override
  void d(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {}
  @override
  void w(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {}
  @override
  void e(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {}
}

const _emptyForbidden = ForbiddenAppsConfig(windows: [], macos: []);
const _attemptId = 'attempt-1';

void main() {
  late _MockWindowManagerChannel windowManager;
  late _MockProcessManagerChannel processManager;
  late _MockClipboardMonitorChannel clipboard;
  late _MockShortcutInterceptorChannel shortcuts;
  late _MockViolationReporter reporter;
  late Logger logger;
  late LockdownService service;

  // Stream controllers the mocks push events into.
  late StreamController<String> windowEvents;
  late StreamController<String> processEvents;
  late StreamController<String> shortcutEvents;
  late StreamController<String> clipboardEvents;

  setUpAll(() {
    registerFallbackValue(
      ViolationEvent(
        attemptPublicId: 'fallback',
        type: ViolationType.shortcutBlocked,
        severity: ViolationSeverity.warning,
        timestamp: DateTime(2026),
      ),
    );
  });

  Future<ForbiddenAppsConfig> Function({
    Future<String> Function(String)? assetLoader,
  }) stubLoader(ForbiddenAppsConfig config) {
    return ({Future<String> Function(String)? assetLoader}) async => config;
  }

  setUp(() {
    windowManager = _MockWindowManagerChannel();
    processManager = _MockProcessManagerChannel();
    clipboard = _MockClipboardMonitorChannel();
    shortcuts = _MockShortcutInterceptorChannel();
    reporter = _MockViolationReporter();
    logger = _PlatformLogger();

    windowEvents = StreamController<String>.broadcast();
    processEvents = StreamController<String>.broadcast();
    shortcutEvents = StreamController<String>.broadcast();
    clipboardEvents = StreamController<String>.broadcast();

    when(() => windowManager.violations)
        .thenAnswer((_) => windowEvents.stream);
    when(() => processManager.violations)
        .thenAnswer((_) => processEvents.stream);
    when(() => shortcuts.violations)
        .thenAnswer((_) => shortcutEvents.stream);
    when(() => clipboard.violations)
        .thenAnswer((_) => clipboardEvents.stream);

    when(() => windowManager.enforceFullscreen()).thenAnswer((_) async {});
    when(() => windowManager.exitFullscreen()).thenAnswer((_) async {});
    when(() => clipboard.blockExternalPaste()).thenAnswer((_) async {});
    when(() => clipboard.clearClipboard()).thenAnswer((_) async {});
    when(() => clipboard.unblock()).thenAnswer((_) async {});
    when(() => shortcuts.blockSystemShortcuts()).thenAnswer((_) async {});
    when(() => shortcuts.unblock()).thenAnswer((_) async {});
    when(() => processManager.getRunningProcesses())
        .thenAnswer((_) async => const <String>[]);
    when(() => reporter.reportViolation(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await windowEvents.close();
    await processEvents.close();
    await shortcutEvents.close();
    await clipboardEvents.close();
  });

  LockdownService build({
    Future<ForbiddenAppsConfig> Function({
      Future<String> Function(String)? assetLoader,
    })? loader,
  }) {
    return LockdownService(
      windowManager: windowManager,
      processManager: processManager,
      clipboard: clipboard,
      shortcuts: shortcuts,
      violationReporter: reporter,
      logger: logger,
      forbiddenConfigLoader: loader ?? stubLoader(_emptyForbidden),
    );
  }

  group('activateLockdown', () {
    test('LockdownMode.none is a documented no-op (no platform calls)', () async {
      service = build();
      await service.activateLockdown(
        mode: LockdownMode.none,
        attemptPublicId: _attemptId,
      );

      expect(service.currentMode, LockdownMode.none);
      expect(service.isActive, isFalse);
      verifyNever(() => windowManager.enforceFullscreen());
      verifyNever(() => clipboard.blockExternalPaste());
      verifyNever(() => shortcuts.blockSystemShortcuts());
    });

    test('standard mode activates the four platform checks but does NOT enumerate processes',
        () async {
      service = build();
      await service.activateLockdown(
        mode: LockdownMode.standard,
        attemptPublicId: _attemptId,
      );

      verify(() => windowManager.enforceFullscreen()).called(1);
      verify(() => clipboard.clearClipboard()).called(1);
      verify(() => clipboard.blockExternalPaste()).called(1);
      verify(() => shortcuts.blockSystemShortcuts()).called(1);
      verifyNever(() => processManager.getRunningProcesses());
      expect(service.currentMode, LockdownMode.standard);
      expect(service.isActive, isTrue);
    });

    test('strict mode skips process enumeration when no forbidden apps are configured',
        () async {
      when(() => processManager.getRunningProcesses())
          .thenAnswer((_) async => const ['system.exe', 'pte_app.exe']);

      service = build();
      await service.initialize();
      await service.activateLockdown(
        mode: LockdownMode.strict,
        attemptPublicId: _attemptId,
      );

      verifyNever(() => processManager.getRunningProcesses());
      verifyNever(() => processManager.terminateProcess(any()));
      verifyNever(() => reporter.reportViolation(any()));
    });

    test('strict mode terminates forbidden apps and reports each as a violation', () async {
      when(() => processManager.getRunningProcesses())
          .thenAnswer((_) async => const ['chrome.exe', 'system.exe']);
      when(() => processManager.terminateProcess('chrome.exe'))
          .thenAnswer((_) async => true);

      service = build(
        loader: stubLoader(
          const ForbiddenAppsConfig(
            windows: [
              ForbiddenApp(
                name: 'Chrome',
                processName: 'chrome.exe',
                category: 'browser',
              ),
            ],
            macos: [],
          ),
        ),
      );
      await service.initialize();
      await service.activateLockdown(
        mode: LockdownMode.strict,
        attemptPublicId: _attemptId,
      );

      verify(() => processManager.terminateProcess('chrome.exe')).called(1);
      final captured = verify(() => reporter.reportViolation(captureAny()))
          .captured;
      expect(captured, hasLength(1));
      final event = captured.single as ViolationEvent;
      expect(event.type, ViolationType.forbiddenAppDetected);
      expect(event.severity, ViolationSeverity.critical);
      expect(event.metadata, contains('chrome.exe'));
    });

    test('rolls back and rethrows when any step fails', () async {
      when(() => shortcuts.blockSystemShortcuts())
          .thenThrow(const ShortcutInterceptionException('hook failed'));

      service = build();

      await expectLater(
        service.activateLockdown(
          mode: LockdownMode.strict,
          attemptPublicId: _attemptId,
        ),
        throwsA(isA<LockdownActivationException>()
            .having((e) => e.failedChecks, 'failedChecks', hasLength(1))),
      );

      // Teardown path must have run to restore hooks.
      verify(() => windowManager.exitFullscreen()).called(1);
      verify(() => clipboard.unblock()).called(1);
      verify(() => shortcuts.unblock()).called(1);
      expect(service.currentMode, LockdownMode.none);
    });

    test('a second concurrent activate attempt is rejected (no re-arm burst)', () async {
      service = build();
      await service.activateLockdown(
        mode: LockdownMode.standard,
        attemptPublicId: _attemptId,
      );
      await service.activateLockdown(
        mode: LockdownMode.standard,
        attemptPublicId: _attemptId,
      );

      // Only the first call should produce any platform traffic.
      verify(() => windowManager.enforceFullscreen()).called(1);
    });
  });

  group('deactivateLockdown', () {
    test('tears down all controls even if some platform calls fail', () async {
      service = build();
      await service.activateLockdown(
        mode: LockdownMode.standard,
        attemptPublicId: _attemptId,
      );

      when(() => shortcuts.unblock()).thenThrow(
        const ShortcutInterceptionException('unhook failed'),
      );

      await service.deactivateLockdown();

      verify(() => windowManager.exitFullscreen()).called(1);
      verify(() => clipboard.unblock()).called(1);
      verify(() => shortcuts.unblock()).called(1);
      expect(service.currentMode, LockdownMode.none);
    });

    test('is idempotent when no lockdown is active', () async {
      service = build();
      await service.deactivateLockdown();
      verifyNever(() => windowManager.exitFullscreen());
    });
  });

  group('violation reporting', () {
    test('relays every recognized event type into the reporter at warning severity', () async {
      service = build();
      await service.activateLockdown(
        mode: LockdownMode.standard,
        attemptPublicId: _attemptId,
      );

      windowEvents.add('FULLSCREEN_EXIT');
      processEvents.add('NEW_FORBIDDEN_APP:discord.exe');
      shortcutEvents.add('ALT_TAB');
      clipboardEvents.add('CLIPBOARD_PASTE');

      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => reporter.reportViolation(captureAny()))
          .captured
          .cast<ViolationEvent>();
      expect(
        captured.map((e) => e.type),
        containsAllInOrder([
          ViolationType.fullscreenExit,
          ViolationType.forbiddenAppDetected,
          ViolationType.shortcutBlocked,
          ViolationType.clipboardPaste,
        ]),
      );
      expect(
        captured.every((e) => e.severity == ViolationSeverity.warning),
        isTrue,
      );
    });

    test('escalates to critical severity when lockdownMode is strict', () async {
      service = build();
      await service.activateLockdown(
        mode: LockdownMode.strict,
        attemptPublicId: _attemptId,
      );
      windowEvents.add('FULLSCREEN_EXIT');
      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => reporter.reportViolation(captureAny()))
          .captured
          .cast<ViolationEvent>();
      expect(captured.single.severity, ViolationSeverity.critical);
    });

    test('drops violations when no attempt is active (avoids phantom rows)', () async {
      service = build();
      await service.activateLockdown(
        mode: LockdownMode.none,
        attemptPublicId: _attemptId,
      );
      windowEvents.add('FULLSCREEN_EXIT');
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => reporter.reportViolation(any()));
    });
  });
}
