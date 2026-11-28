import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/platform/clipboard_monitor_channel.dart';
import 'package:pte_app/core/platform/process_manager_channel.dart';
import 'package:pte_app/core/platform/shortcut_interceptor_channel.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';
import 'package:pte_app/core/security/config/forbidden_apps_config.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/security/violation_reporter.dart';

/// FR-02: the per-type violation debounce is measured on a MONOTONIC clock
/// (`LockdownService(monotonicElapsed: ...)`, backed by a `Stopwatch` in
/// production), not on `DateTime.now()`. The wall clock can jump backwards (NTP
/// resync, a student changing the date); with it, `now - previous` goes
/// negative, which is "less than the debounce" and silently drops genuine
/// violations. Because the injected clock is the only time source the debounce
/// may read, these tests hold whatever the wall clock does.
class _MockWindowManagerChannel extends Mock implements WindowManagerChannel {}

class _MockProcessManagerChannel extends Mock
    implements ProcessManagerChannel {}

class _MockClipboardMonitorChannel extends Mock
    implements ClipboardMonitorChannel {}

class _MockShortcutInterceptorChannel extends Mock
    implements ShortcutInterceptorChannel {}

class _MockViolationReporter extends Mock implements ViolationReporter {}

const String _attemptId = 'attempt-debounce';
const String _windowEvent = 'FOCUS_LOSS';
const Duration _debounceWindow = Duration(seconds: 1);
const Duration _justInsideWindow = Duration(milliseconds: 500);
const Duration _wellOutsideWindow = Duration(seconds: 3);

void main() {
  late _MockWindowManagerChannel windowManager;
  late _MockProcessManagerChannel processManager;
  late _MockClipboardMonitorChannel clipboard;
  late _MockShortcutInterceptorChannel shortcuts;
  late _MockViolationReporter reporter;
  late StreamController<String> windowEvents;
  late StreamController<String> shortcutEvents;
  late Duration monotonicNow;
  late LockdownService service;

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

  setUp(() async {
    windowManager = _MockWindowManagerChannel();
    processManager = _MockProcessManagerChannel();
    clipboard = _MockClipboardMonitorChannel();
    shortcuts = _MockShortcutInterceptorChannel();
    reporter = _MockViolationReporter();
    windowEvents = StreamController<String>.broadcast();
    shortcutEvents = StreamController<String>.broadcast();
    monotonicNow = Duration.zero;

    when(() => windowManager.violations).thenAnswer((_) => windowEvents.stream);
    when(() => processManager.violations)
        .thenAnswer((_) => const Stream<String>.empty());
    when(() => shortcuts.violations).thenAnswer((_) => shortcutEvents.stream);
    when(() => clipboard.violations)
        .thenAnswer((_) => const Stream<String>.empty());
    when(() => windowManager.setExitGuardActive(any()))
        .thenAnswer((_) async {});
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
      monotonicElapsed: () => monotonicNow,
    );
    await service.activateAttemptExitGuard(attemptPublicId: _attemptId);
  });

  tearDown(() async {
    await windowEvents.close();
    await shortcutEvents.close();
  });

  Future<void> emitWindowViolation() async {
    windowEvents.add(_windowEvent);
    await Future<void>.delayed(Duration.zero);
  }

  int reportedCount() =>
      verify(() => reporter.reportViolation(any())).callCount;

  group('debounce on the monotonic clock', () {
    test('a repeat inside the debounce window is dropped', () async {
      await emitWindowViolation();
      monotonicNow += _justInsideWindow;
      await emitWindowViolation();

      expect(reportedCount(), 1);
    });

    test('a repeat after the window is reported even if both arrive back to back in real time', () async {
      await emitWindowViolation();
      monotonicNow += _wellOutsideWindow;
      await emitWindowViolation();

      expect(reportedCount(), 2);
    });

    test('a repeat exactly one debounce window later is reported', () async {
      await emitWindowViolation();
      monotonicNow += _debounceWindow;
      await emitWindowViolation();

      expect(reportedCount(), 2);
    });

    test('every genuine violation in a long exam is reported', () async {
      for (var index = 0; index < 5; index++) {
        await emitWindowViolation();
        monotonicNow += _wellOutsideWindow;
      }

      expect(reportedCount(), 5);
    });

    test('the window is tracked per violation type', () async {
      await emitWindowViolation();
      shortcutEvents.add('ALT_TAB');
      await Future<void>.delayed(Duration.zero);

      expect(reportedCount(), 2);
    });
  });
}
