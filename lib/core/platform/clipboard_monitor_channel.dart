import 'package:flutter/services.dart';

import 'package:pte_app/core/platform/lockdown_exception.dart';

/// Platform channel for clipboard monitoring and blocking on Windows. Every
/// error is remapped to [ClipboardException] so callers never handle raw
/// [PlatformException].
class ClipboardMonitorChannel {
  const ClipboardMonitorChannel();

  static const _platform = MethodChannel('com.pte.lockdown/clipboard');
  static const _eventChannel =
      EventChannel('com.pte.lockdown/clipboard/events');

  /// Block external clipboard paste operations.
  /// Internal app copy/paste still allowed.
  Future<void> blockExternalPaste() async {
    try {
      await _platform.invokeMethod<void>('blockExternalPaste');
    } on PlatformException catch (e) {
      throw ClipboardException('Failed to block clipboard: ${e.message}');
    }
  }

  /// Clear system clipboard content.
  Future<void> clearClipboard() async {
    try {
      await _platform.invokeMethod<void>('clearClipboard');
    } on PlatformException catch (e) {
      throw ClipboardException('Failed to clear clipboard: ${e.message}');
    }
  }

  /// Unblock clipboard operations.
  Future<void> unblock() async {
    try {
      await _platform.invokeMethod<void>('unblock');
    } on PlatformException catch (e) {
      throw ClipboardException('Failed to unblock clipboard: ${e.message}');
    }
  }

  /// Stream of clipboard violation events (external source detected while
  /// blocking is active). Distinct from process violations because the
  /// clipboard channel is the only one that knows about copy/paste flows.
  Stream<String> get violations {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String);
  }
}
