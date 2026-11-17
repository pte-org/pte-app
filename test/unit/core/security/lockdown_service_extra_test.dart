import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/platform/clipboard_monitor_channel.dart';
import 'package:pte_app/core/platform/process_manager_channel.dart';
import 'package:pte_app/core/platform/shortcut_interceptor_channel.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';
import 'package:pte_app/core/security/config/forbidden_apps_config.dart';
import 'package:pte_app/core/security/lockdown_mode.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/security/violation_reporter.dart';

class _MockWindowManagerChannel extends Mock implements WindowManagerChannel {}
class _MockProcessManagerChannel extends Mock implements ProcessManagerChannel {}
class _MockClipboardMonitorChannel extends Mock implements ClipboardMonitorChannel {}
class _MockShortcutInterceptorChannel extends Mock implements ShortcutInterceptorChannel {}
class _MockViolationReporter extends Mock implements ViolationReporter {}

void main() {
  late _MockWindowManagerChannel windowManager;
  late _MockProcessManagerChannel processManager;
  late _MockClipboardMonitorChannel clipboard;
  late _MockShortcutInterceptorChannel shortcuts;
  late _MockViolationReporter reporter;
  late LockdownService service;

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

  setUp(() {
    windowManager = _MockWindowManagerChannel();
    processManager = _MockProcessManagerChannel();
    clipboard = _MockClipboardMonitorChannel();
    shortcuts = _MockShortcutInterceptorChannel();
    reporter = _MockViolationReporter();

    windowEvents = StreamController<String>.broadcast();
    processEvents = StreamController<String>.broadcast();
    shortcutEvents = StreamController<String>.broadcast();
    clipboardEvents = StreamController<String>.broadcast();

    when(() => windowManager.violations).thenAnswer((_) => windowEvents.stream);
    when(() => processManager.violations).thenAnswer((_) => processEvents.stream);
    when(() => shortcuts.violations).thenAnswer((_) => shortcutEvents.stream);
    when(() => clipboard.violations).thenAnswer((_) => clipboardEvents.stream);

    when(() => windowManager.enforceFullscreen()).thenAnswer((_) async {});
    when(() => windowManager.exitFullscreen()).thenAnswer((_) async {});
    when(() => windowManager.setExitGuardActive(any())).thenAnswer((_) async {});
    when(() => windowManager.setExitAllowed(any())).thenAnswer((_) async {});
    when(() => reporter.reportViolation(any())).thenAnswer((_) async {});

    service = LockdownService(
      windowManager: windowManager,
      processManager: processManager,
      clipboard: clipboard,
      shortcuts: shortcuts,
      violationReporter: reporter,
      logger: Logger(printer: PrettyPrinter(methodCount: 0)),
      forbiddenConfigLoader: ({assetLoader}) async =>
          const ForbiddenAppsConfig(windows: [], macos: []),
    );
  });

  tearDown(() async {
    await windowEvents.close();
    await processEvents.close();
    await shortcutEvents.close();
    await clipboardEvents.close();
  });

  group('LockdownService edge cases and lifecycle coverage', () {
    test('LockdownActivationException toString outputs message and failedChecks', () {
      const ex = LockdownActivationException(
        'Failed',
        failedChecks: ['check-1', 'check-2'],
      );
      expect(ex.toString(), contains('LockdownActivationException(Failed'));
      expect(ex.toString(), contains('check-1'));
      expect(ex.toString(), contains('check-2'));
    });

    test('activateLockdown with mode none cleans up and remains none', () async {
      await service.activateLockdown(
        mode: LockdownMode.none,
        attemptPublicId: 'attempt-none',
      );
      expect(service.currentMode, equals(LockdownMode.none));
      expect(service.isActive, isFalse);
    });

    test('violations stream getter broadcasts events and stops after dispose', () async {
      await service.activateAttemptExitGuard(attemptPublicId: 'att-stream');
      final received = <ViolationType>[];
      final sub = service.violations.listen(received.add);

      windowEvents.add('user_exited_fullscreen');
      await Future<void>.delayed(Duration.zero);

      expect(received, equals([ViolationType.fullscreenExit]));
      await sub.cancel();

      await service.dispose();
      expect(service.isActive, isFalse);
      expect(service.isDeviceCheckFullscreenActive, isFalse);
    });

    test('stream error callbacks on monitors log warning without throwing', () async {
      await service.activateAttemptExitGuard(attemptPublicId: 'att-errors');

      windowEvents.addError(Exception('window stream failed'));
      processEvents.addError(Exception('process stream failed'));
      shortcutEvents.addError(Exception('shortcut stream failed'));
      clipboardEvents.addError(Exception('clipboard stream failed'));

      await Future<void>.delayed(Duration.zero);
      expect(service.isExitAllowed, isFalse);
    });

    test('enterDeviceCheckFullscreen logs warning when rollback throws', () async {
      when(() => windowManager.enforceFullscreen())
          .thenThrow(Exception('enforce failed'));
      when(() => windowManager.exitFullscreen())
          .thenThrow(Exception('rollback exit failed'));

      await expectLater(
        service.enterDeviceCheckFullscreen(),
        throwsA(isA<LockdownActivationException>()),
      );
    });

    test('exitDeviceCheckFullscreen catches and logs error on exit failure', () async {
      await service.enterDeviceCheckFullscreen();
      expect(service.isDeviceCheckFullscreenActive, isTrue);

      when(() => windowManager.exitFullscreen())
          .thenThrow(Exception('exit failed'));
      await service.exitDeviceCheckFullscreen();
      expect(service.isDeviceCheckFullscreenActive, isFalse);
    });

    test('activateAttemptExitGuard handles rollback failure when native throws', () async {
      when(() => windowManager.setExitGuardActive(true))
          .thenThrow(Exception('native activate failed'));
      when(() => windowManager.setExitAllowed(true))
          .thenThrow(Exception('native rollback failed'));

      await expectLater(
        service.activateAttemptExitGuard(attemptPublicId: 'att-roll'),
        throwsException,
      );
    });

    test('abortAttemptExitGuard rethrows first error when setExitAllowed throws', () async {
      await service.activateAttemptExitGuard(attemptPublicId: 'att-abort');
      when(() => windowManager.setExitAllowed(true))
          .thenThrow(Exception('setExitAllowed abort error'));

      await expectLater(
        service.abortAttemptExitGuard(),
        throwsException,
      );
      expect(service.isExitAllowed, isTrue);
    });

    test('deactivateAttemptExitGuard logs warning if exit was not allowed first', () async {
      await service.activateAttemptExitGuard(attemptPublicId: 'att-forced');
      expect(service.isExitAllowed, isFalse);

      await service.deactivateAttemptExitGuard();
      expect(service.isExitAllowed, isFalse);
    });
  });
}
