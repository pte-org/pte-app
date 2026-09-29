import 'package:flutter/services.dart';

import 'package:pte_app/core/platform/lockdown_exception.dart';

/// Platform channel for Windows window management (fullscreen enforcement and
/// escape detection). Every error is remapped to
/// [FullscreenEnforcementException] so callers never handle raw
/// [PlatformException].
class WindowManagerChannel {
  const WindowManagerChannel();

  static const _platform = MethodChannel('com.pte.lockdown/window');
  static const _eventChannel = EventChannel('com.pte.lockdown/window/events');

  /// Enforce fullscreen mode - disables window controls, prevents escape.
  /// Throws [FullscreenEnforcementException] if enforcement fails.
  Future<void> enforceFullscreen() async {
    try {
      await _platform.invokeMethod<void>('enforceFullscreen');
    } on PlatformException catch (e) {
      throw FullscreenEnforcementException(
        'Failed to enforce fullscreen: ${e.message}',
      );
    }
  }

  /// Exit fullscreen mode - restores normal window state.
  Future<void> exitFullscreen() async {
    try {
      await _platform.invokeMethod<void>('exitFullscreen');
    } on PlatformException catch (e) {
      throw FullscreenEnforcementException(
        'Failed to exit fullscreen: ${e.message}',
      );
    }
  }

  /// Installs or removes the app-level exam exit gate. The native runner
  /// keeps this state independently from fullscreen so Practice/NONE can use
  /// the submit-before-exit rule without being forced into fullscreen.
  Future<void> setExitGuardActive(bool active) async {
    try {
      await _platform.invokeMethod<void>('setExitGuardActive', active);
    } on MissingPluginException {
      // Non-Windows builds have no native window guard. The student app's
      // Dart state machine remains authoritative and safe to test there.
      return;
    } on PlatformException catch (e) {
      throw ExitGuardException(
        'Failed to ${active ? 'activate' : 'deactivate'} exit guard: ${e.message}',
      );
    }
  }

  /// Allows or refuses native window exit while the guard is active. The
  /// permission is explicit; native code must not infer it from a route.
  Future<void> setExitAllowed(bool allowed) async {
    try {
      await _platform.invokeMethod<void>('setExitAllowed', allowed);
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      throw ExitGuardException(
        'Failed to ${allowed ? 'allow' : 'block'} window exit: ${e.message}',
      );
    }
  }

  /// Stream of fullscreen violation events.
  /// Emits event type string when user attempts to escape fullscreen.
  Stream<String> get violations {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String);
  }
}
