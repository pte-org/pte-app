import 'package:flutter/services.dart';

import 'package:pte_app/core/platform/lockdown_exception.dart';

/// Platform channel for clipboard monitoring and blocking. Maps to Windows
/// OpenClipboard/EmptyClipboard and macOS NSPasteboard. Every error is
/// remapped to [ClipboardException] so callers never handle raw
/// [PlatformException].
class ClipboardMonitorChannel {
  const ClipboardMonitorChannel();

  static const _platform = MethodChannel('com.pte.lockdown/clipboard');

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
}
