/// Exception hierarchy for lockdown platform channels. Follows the sealed
/// class pattern established by [ApiException] in `api_exceptions.dart` —
/// every platform channel error is mapped to a specific subtype here so
/// callers branch on type, never on a raw [PlatformException] code.
sealed class LockdownException implements Exception {
  const LockdownException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Fullscreen enforcement failed (window handle unavailable, SetWindowLong
/// failed, or monitor info retrieval failed on Windows).
final class FullscreenEnforcementException extends LockdownException {
  const FullscreenEnforcementException(super.message);
}

/// Process enumeration or termination failed (CreateToolhelp32Snapshot
/// failed on Windows, or insufficient permissions for TerminateProcess).
final class ProcessManagementException extends LockdownException {
  const ProcessManagementException(super.message);
}

/// Clipboard operation failed (OpenClipboard/EmptyClipboard failed on
/// Windows, or NSPasteboard access denied on macOS).
final class ClipboardException extends LockdownException {
  const ClipboardException(super.message);
}

/// Keyboard hook installation failed (SetWindowsHookEx returned null on
/// Windows, or NSEvent.addGlobalMonitorForEvents failed on macOS).
final class ShortcutInterceptionException extends LockdownException {
  const ShortcutInterceptionException(super.message);
}
