import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import 'package:pte_app/core/platform/clipboard_monitor_channel.dart';
import 'package:pte_app/core/platform/lockdown_exception.dart';
import 'package:pte_app/core/platform/process_manager_channel.dart';
import 'package:pte_app/core/platform/shortcut_interceptor_channel.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';
import 'package:pte_app/core/security/config/forbidden_apps_config.dart';
import 'package:pte_app/core/security/lockdown_mode.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/security/violation_reporter.dart';

/// Thrown by [LockdownService.activateLockdown] when at least one
/// underlying platform call failed. The list of [failedChecks] gives
/// the UI enough information to render the
/// "Cannot Start Exam" dialog (Phase 5 owns the public-facing UI; this
/// only carries the data).
class LockdownActivationException implements Exception {
  const LockdownActivationException(
    this.message, {
    this.failedChecks = const [],
    this.cause,
  });

  final String message;
  final List<String> failedChecks;
  final Object? cause;

  @override
  String toString() =>
      'LockdownActivationException($message, '
      'failedChecks=$failedChecks)';
}

/// Orchestrates the four Phase 2 platform channels: enforce fullscreen,
/// block clipboard, block shortcuts, terminate forbidden apps. Owns the
/// violation subscription lifecycle so the rest of the app doesn't have
/// to remember which stream pairs with which channel.
///
/// Lifecycle contract:
///   - [initialize] must be called once before any [activateLockdown]
///     call (typically from `main.dart` after `setupSecurityModule`).
///   - [activateLockdown] is **idempotent in the failure sense**: if
///     any step throws, [deactivateLockdown] runs first so a half-armed
///     lockdown never lingers.
///   - [deactivateLockdown] is safe to call when nothing is active.
class LockdownService {
  LockdownService({
    required WindowManagerChannel windowManager,
    required ProcessManagerChannel processManager,
    required ClipboardMonitorChannel clipboard,
    required ShortcutInterceptorChannel shortcuts,
    required ViolationReporter violationReporter,
    required Logger logger,
    Future<ForbiddenAppsConfig> Function({
      Future<String> Function(String)? assetLoader,
    })?
    forbiddenConfigLoader,
  }) : _windowManager = windowManager,
       _processManager = processManager,
       _clipboard = clipboard,
       _shortcuts = shortcuts,
       _violationReporter = violationReporter,
       _logger = logger,
       _forbiddenConfigLoader =
           forbiddenConfigLoader ?? ForbiddenAppsConfig.load;

  final WindowManagerChannel _windowManager;
  final ProcessManagerChannel _processManager;
  final ClipboardMonitorChannel _clipboard;
  final ShortcutInterceptorChannel _shortcuts;
  final ViolationReporter _violationReporter;
  final Logger _logger;
  final Future<ForbiddenAppsConfig> Function({
    Future<String> Function(String)? assetLoader,
  })
  _forbiddenConfigLoader;

  ForbiddenAppsConfig? _forbiddenAppsConfig;

  LockdownMode _currentMode = LockdownMode.none;
  String? _currentAttemptId;
  bool _deviceCheckFullscreenActive = false;
  bool _attemptExitGuardActive = false;
  bool _exitAllowed = false;
  bool _violationMonitoringActive = false;
  final Map<ViolationType, DateTime> _lastViolationAt = {};
  static const _violationDebounce = Duration(seconds: 1);
  final List<StreamSubscription<String>> _violationSubscriptions = [];

  /// Broadcast of the most recent [ViolationType] seen while the
  /// service is active. Used by `ViolationWarningBanner` (Phase 5) to
  /// surface a short-lived UI warning. Replaying the same type twice
  /// yields two emissions on purpose so listeners can show a banner
  /// every time the OS notifies us, not just the first.
  final StreamController<ViolationType> _violationStreamController =
      StreamController<ViolationType>.broadcast();

  /// Public read-only stream. Listeners must resubscribe on
  /// [deactivateLockdown]/[activateLockdown] transitions if they want
  /// to model those explicitly; the broadcast controller survives
  /// deactivation without losing its subscriptions.
  Stream<ViolationType> get violations => _violationStreamController.stream;

  /// Active lockdown mode — `none` when no attempt is currently running.
  LockdownMode get currentMode => _currentMode;

  /// Convenience: returns true when [_currentMode] is anything except
  /// `none`. The UI's "lockdown active" badge uses this.
  bool get isActive => _currentMode != LockdownMode.none;

  /// Returns true while the pre-attempt device check owns fullscreen.
  ///
  /// This is intentionally separate from [isActive]. Device-check fullscreen
  /// does not install shortcut/clipboard/process hooks and has no attempt ID,
  /// so it must not be treated as an active anti-cheat lockdown.
  bool get isDeviceCheckFullscreenActive => _deviceCheckFullscreenActive;

  /// True while the native runner refuses app-level close/minimize actions
  /// for the current attempt. This is intentionally separate from
  /// [isActive], because `NONE` lockdown still enables the submit-before-exit
  /// gate without enabling anti-cheat fullscreen.
  bool get isAttemptExitGuardActive => _attemptExitGuardActive;

  /// True only after the server-acknowledged terminal submission path grants
  /// the native runner permission to close the exam window.
  bool get isExitAllowed => _exitAllowed;

  /// Installs the app-level exit guard for a real attempt. It does not change
  /// fullscreen, clipboard, shortcuts, or process policy; those remain owned
  /// by [activateLockdown] and the server-pinned lockdown mode.
  Future<void> activateAttemptExitGuard({
    required String attemptPublicId,
  }) async {
    if (_attemptExitGuardActive && _currentAttemptId == attemptPublicId) {
      return;
    }

    _logger.i('Activating app-level exit guard for $attemptPublicId');
    _lastViolationAt.clear();
    try {
      // Refuse first, then turn the native gate on. Native defaults to the
      // blocked posture, so a transient message between these calls cannot
      // become an accidental exit window.
      await _windowManager.setExitAllowed(false);
      await _windowManager.setExitGuardActive(true);
      _attemptExitGuardActive = true;
      _exitAllowed = false;
      _currentAttemptId = attemptPublicId;
      if (!_violationMonitoringActive) {
        _startViolationMonitoring();
      }
    } on Object {
      // If activation failed after changing the native permission, restore a
      // harmless non-guard posture before surfacing the failure.
      try {
        await _windowManager.setExitGuardActive(false);
        await _windowManager.setExitAllowed(true);
      } on Object catch (rollbackError) {
        _logger.w('Exit guard rollback failed', error: rollbackError);
      }
      rethrow;
    }
  }

  /// Grants native close permission after the backend has acknowledged the
  /// terminal submit. Calling this before that boundary is a contract bug and
  /// is therefore intentionally not inferred from a widget state.
  Future<void> allowExitAfterSubmission() async {
    if (!_attemptExitGuardActive || _exitAllowed) return;
    await _windowManager.setExitAllowed(true);
    _exitAllowed = true;
    _logger.i('App-level exit guard unlocked after submission acknowledgement');
  }

  /// Releases a guard whose attempt never reached the task shell (for
  /// example, a post-start bootstrap failure). This is deliberately separate
  /// from [deactivateAttemptExitGuard]: normal teardown refuses to remove a
  /// still-blocked guard without server acknowledgement.
  Future<void> abortAttemptExitGuard() async {
    if (!_attemptExitGuardActive) return;

    Object? firstError;
    StackTrace? firstStack;
    try {
      await _windowManager.setExitAllowed(true);
    } on Object catch (e, stack) {
      firstError = e;
      firstStack = stack;
    }
    try {
      await _windowManager.setExitGuardActive(false);
    } on Object catch (e, stack) {
      firstError ??= e;
      firstStack ??= stack;
    }

    _attemptExitGuardActive = false;
    _exitAllowed = true;
    if (_currentMode == LockdownMode.none) {
      _stopViolationMonitoring();
      _currentAttemptId = null;
    }
    _logger.i('App-level exit guard aborted before the attempt started');

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack!);
    }
  }

  /// Removes the native guard after the submitted state has been exposed.
  /// [allowExitAfterSubmission] must run first; this method does not grant
  /// permission on its own.
  Future<void> deactivateAttemptExitGuard() async {
    if (!_attemptExitGuardActive) return;
    if (!_exitAllowed) {
      _logger.w(
        'Refusing to deactivate app-level exit guard before submission acknowledgement',
      );
      return;
    }
    await _windowManager.setExitGuardActive(false);
    _attemptExitGuardActive = false;
    _exitAllowed = true;
    if (_currentMode == LockdownMode.none) {
      _stopViolationMonitoring();
      _currentAttemptId = null;
    }
    _logger.i('App-level exit guard deactivated');
  }

  /// Puts the candidate in fullscreen before the device check begins.
  ///
  /// Only the window state is changed here. Audit events are deliberately not
  /// emitted because the backend has not created an attempt yet. The later
  /// [activateLockdown] call reuses this fullscreen state and binds the full
  /// enforcement stack to the real attempt ID.
  Future<void> enterDeviceCheckFullscreen() async {
    if (_deviceCheckFullscreenActive || _currentMode != LockdownMode.none) {
      return;
    }

    try {
      await _windowManager.enforceFullscreen();
      _deviceCheckFullscreenActive = true;
      _logger.i('Device-check fullscreen activated');
    } on Object catch (e, stack) {
      _logger.e(
        'Device-check fullscreen activation failed',
        error: e,
        stackTrace: stack,
      );
      // The native implementation normally rolls back a partial window
      // change. Keep the service safe if a platform implementation does not.
      try {
        await _windowManager.exitFullscreen();
      } on Object catch (rollbackError) {
        _logger.w(
          'Device-check fullscreen rollback failed',
          error: rollbackError,
        );
      }
      throw LockdownActivationException(
        'Device-check fullscreen activation failed',
        failedChecks: ['enforceFullscreen: $e'],
        cause: e,
      );
    }
  }

  /// Releases fullscreen that was entered only for the device check.
  ///
  /// This is a no-op once the real lockdown has taken ownership of the
  /// window, or when the device check was never entered.
  Future<void> exitDeviceCheckFullscreen() async {
    if (!_deviceCheckFullscreenActive) return;

    try {
      await _windowManager.exitFullscreen();
    } on Object catch (e) {
      _logger.w('Device-check fullscreen teardown failed', error: e);
    } finally {
      _deviceCheckFullscreenActive = false;
    }
  }

  /// Idempotent bootstrap. Loads the bundled forbidden-apps JSON and
  /// keeps it cached — subsequent activates are cheap. The loader is
  /// expected to throw on a malformed asset; the error is surfaced as
  /// an exception so main.dart can crash loudly during development.
  Future<void> initialize() async {
    if (_forbiddenAppsConfig != null) return;
    try {
      _forbiddenAppsConfig = await _forbiddenConfigLoader();
      final platformCount =
          _forbiddenAppsConfig?.getForCurrentPlatform().length ?? 0;
      _logger.i(
        'LockdownService initialized with $platformCount forbidden app(s)',
      );
    } catch (e, stack) {
      _logger.e(
        'LockdownService.initialize failed to load forbidden apps config',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Activates the enforcement stack. Returns when every enabled step
  /// has completed. On partial failure rolls back via
  /// [deactivateLockdown] and rethrows a [LockdownActivationException]
  /// listing the failed steps.
  Future<void> activateLockdown({
    required LockdownMode mode,
    required String attemptPublicId,
  }) async {
    if (mode == LockdownMode.none) {
      _logger.w('Attempted to activate lockdown with mode NONE — no-op');
      await exitDeviceCheckFullscreen();
      _currentMode = LockdownMode.none;
      _currentAttemptId = null;
      return;
    }
    if (_currentMode != LockdownMode.none) {
      // Already active — refuse to silently re-arm, the proctor would
      // see two full event bursts. Caller must explicitly tear down.
      _logger.w(
        'Lockdown already active in mode ${_currentMode.name}; '
        'ignoring re-activation for $attemptPublicId',
      );
      return;
    }

    _logger.i('Activating lockdown mode: ${mode.name} for $attemptPublicId');
    _currentMode = mode;
    _currentAttemptId = attemptPublicId;
    final failed = <String>[];

    Future<void> step(String label, Future<void> Function() body) async {
      try {
        await body();
        _logger.d('Lockdown step OK: $label');
      } on PlatformException catch (e) {
        _logger.e('Lockdown step failed: $label', error: e);
        failed.add('$label: ${e.message ?? e.code}');
      } on LockdownException catch (e) {
        _logger.e('Lockdown step failed: $label', error: e);
        failed.add('$label: ${e.message}');
      } on Object catch (e) {
        _logger.e('Lockdown step failed: $label', error: e);
        failed.add('$label: $e');
      }
    }

    try {
      await step('enforceFullscreen', _windowManager.enforceFullscreen);
      await step('clearClipboard', _clipboard.clearClipboard);
      await step('blockExternalPaste', _clipboard.blockExternalPaste);
      await step('blockSystemShortcuts', _shortcuts.blockSystemShortcuts);

      if (mode == LockdownMode.strict) {
        await step('terminateForbiddenApps', _terminateForbiddenApps);
      }

      _startViolationMonitoring();

      if (failed.isNotEmpty) {
        throw LockdownActivationException(
          'Lockdown activation failed for '
          '${failed.length} step(s)',
          failedChecks: failed,
        );
      }
      // The real lockdown now owns the already-fullscreen window. Do not let
      // a later device-check cleanup restore it underneath the attempt.
      _deviceCheckFullscreenActive = false;
      _logger.i('Lockdown activated successfully');
    } catch (e) {
      await deactivateLockdown();
      rethrow;
    }
  }

  Future<void> deactivateLockdown() async {
    if (_currentMode == LockdownMode.none) {
      // No-op idempotent path so callers can use this method as a
      // "reset" without first checking state.
      await exitDeviceCheckFullscreen();
      return;
    }
    _logger.i('Deactivating lockdown');

    // The app-level exit guard may remain active while anti-cheat controls
    // are being torn down (for example, a process lifecycle interruption).
    // Keep its warning/audit stream alive until the explicit guard release.
    if (!_attemptExitGuardActive) {
      _stopViolationMonitoring();
    }

    // Each step is wrapped in its own try/catch — on the deactivate
    // path a partial failure is less catastrophic than on the
    // activate path, and we never want to leave hooks dangling just
    // because one teardown step errored.
    Future<void> safe(String label, Future<void> Function() body) async {
      try {
        await body();
      } on Object catch (e) {
        _logger.w('Lockdown teardown step failed: $label', error: e);
      }
    }

    await safe('exitFullscreen', _windowManager.exitFullscreen);
    await safe('unblockClipboard', _clipboard.unblock);
    await safe('unblockShortcuts', _shortcuts.unblock);

    _currentMode = LockdownMode.none;
    if (!_attemptExitGuardActive) {
      _currentAttemptId = null;
    }
    _deviceCheckFullscreenActive = false;
    _logger.i('Lockdown deactivated');
  }

  Future<void> _terminateForbiddenApps() async {
    final config = _forbiddenAppsConfig;
    if (config == null) {
      _logger.w('Forbidden apps config not loaded; skipping termination');
      return;
    }
    final forbidden = config.getForCurrentPlatform();
    if (forbidden.isEmpty) {
      _logger.d('No forbidden apps configured for this platform');
      return;
    }
    final forbiddenNames = forbidden.map((a) => a.processName).toSet();
    List<String> runningForbidden;
    try {
      final running = await _processManager.getRunningProcesses();
      runningForbidden = running
          .where((name) => forbiddenNames.contains(name))
          .toList();
    } catch (e) {
      // Enumeration itself failed — surface to the activate step so the
      // "strict mode failed" dialog can show "could not enumerate
      // processes" as one of the failed checks.
      throw LockdownActivationException(
        'Failed to enumerate running processes',
        cause: e,
      );
    }

    if (runningForbidden.isEmpty) {
      _logger.d('No forbidden apps running');
      return;
    }
    _logger.w(
      'Found ${runningForbidden.length} forbidden app(s): '
      '${runningForbidden.join(", ")}',
    );
    for (final processName in runningForbidden) {
      try {
        final ok = await _processManager.terminateProcess(processName);
        _logger.i('Terminated forbidden app $processName: $ok');
      } catch (e) {
        _logger.e('Failed to terminate $processName', error: e);
      }
      if (_currentAttemptId != null) {
        await _violationReporter.reportViolation(
          ViolationEvent(
            attemptPublicId: _currentAttemptId!,
            type: ViolationType.forbiddenAppDetected,
            severity: ViolationSeverity.critical,
            timestamp: DateTime.now(),
            metadata: '{"processName":"$processName"}',
          ),
        );
      }
    }
  }

  void _startViolationMonitoring() {
    if (_violationMonitoringActive) return;
    _violationMonitoringActive = true;
    _logger.d('Starting violation monitoring');
    _violationSubscriptions.add(
      _windowManager.violations.listen(
        (event) => _handleViolation(ViolationType.fullscreenExit, event),
        onError: (Object e) => _logger.w('window event stream error', error: e),
      ),
    );
    _violationSubscriptions.add(
      _processManager.violations.listen(
        (event) => _handleViolation(ViolationType.forbiddenAppDetected, event),
        onError: (Object e) =>
            _logger.w('process event stream error', error: e),
      ),
    );
    _violationSubscriptions.add(
      _shortcuts.violations.listen(
        (event) => _handleViolation(ViolationType.shortcutBlocked, event),
        onError: (Object e) =>
            _logger.w('shortcut event stream error', error: e),
      ),
    );
    _violationSubscriptions.add(
      _clipboard.violations.listen(
        (event) => _handleViolation(ViolationType.clipboardPaste, event),
        onError: (Object e) =>
            _logger.w('clipboard event stream error', error: e),
      ),
    );
  }

  void _stopViolationMonitoring() {
    if (!_violationMonitoringActive) return;
    _violationMonitoringActive = false;
    _logger.d('Stopping violation monitoring');
    for (final subscription in _violationSubscriptions) {
      subscription.cancel();
    }
    _violationSubscriptions.clear();
  }

  Future<void> _handleViolation(ViolationType type, String? metadata) async {
    final attemptId = _currentAttemptId;
    if (attemptId == null) {
      _logger.w(
        'Violation ${type.name} detected but no active attempt — dropping',
      );
      return;
    }
    final now = DateTime.now();
    final previous = _lastViolationAt[type];
    if (previous != null && now.difference(previous) < _violationDebounce) {
      _logger.d('Debounced repeated violation: ${type.name}');
      return;
    }
    _lastViolationAt[type] = now;
    _logger.w('Violation detected: ${type.name}');
    if (!_violationStreamController.isClosed) {
      _violationStreamController.add(type);
    }
    final severity = _currentMode == LockdownMode.strict
        ? ViolationSeverity.critical
        : ViolationSeverity.warning;
    await _violationReporter.reportViolation(
      ViolationEvent(
        attemptPublicId: attemptId,
        type: type,
        severity: severity,
        timestamp: now,
        metadata: metadata,
      ),
    );
  }

  /// Drops the broadcast controller. Called from `ExamAttemptBloc.close()`
  /// to guarantee no listener outlives a discarded service instance
  /// during a hard-stop shutdown.
  Future<void> dispose() async {
    await deactivateAttemptExitGuard();
    await deactivateLockdown();
    await exitDeviceCheckFullscreen();
    if (!_violationStreamController.isClosed) {
      await _violationStreamController.close();
    }
  }
}
