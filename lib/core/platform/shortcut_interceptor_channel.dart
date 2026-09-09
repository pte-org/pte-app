import 'package:flutter/services.dart';

import 'package:pte_app/core/platform/lockdown_exception.dart';

/// Platform channel for system shortcut interception on Windows. Maps to
/// SetWindowsHookEx(WH_KEYBOARD_LL). Every error is remapped to
/// [ShortcutInterceptionException] so callers never handle raw
/// [PlatformException].
class ShortcutInterceptorChannel {
  const ShortcutInterceptorChannel();

  static const _platform = MethodChannel('com.pte.lockdown/shortcuts');
  static const _eventChannel =
      EventChannel('com.pte.lockdown/shortcuts/events');

  /// Block system shortcuts (Alt+Tab, Win+D, PrintScreen, etc.).
  Future<void> blockSystemShortcuts() async {
    try {
      await _platform.invokeMethod<void>('blockSystemShortcuts');
    } on PlatformException catch (e) {
      throw ShortcutInterceptionException(
        'Failed to block shortcuts: ${e.message}',
      );
    }
  }

  /// Unblock system shortcuts.
  Future<void> unblock() async {
    try {
      await _platform.invokeMethod<void>('unblock');
    } on PlatformException catch (e) {
      throw ShortcutInterceptionException(
        'Failed to unblock shortcuts: ${e.message}',
      );
    }
  }

  /// Stream of shortcut violation events (blocked key combo detected).
  Stream<String> get violations {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String);
  }
}
