import 'package:flutter/services.dart';

import 'package:pte_app/core/platform/lockdown_exception.dart';

/// Platform channel for process management on Windows. Maps to Windows
/// CreateToolhelp32Snapshot/TerminateProcess. Every error is remapped to
/// [ProcessManagementException] so callers never handle raw
/// [PlatformException].
class ProcessManagerChannel {
  const ProcessManagerChannel();

  static const _platform = MethodChannel('com.pte.lockdown/process');
  static const _eventChannel = EventChannel('com.pte.lockdown/process/events');

  /// Get list of currently running process names.
  Future<List<String>> getRunningProcesses() async {
    try {
      final List<dynamic> result =
          await _platform.invokeMethod<List<dynamic>>('getRunningProcesses') ??
              [];
      return result.cast<String>();
    } on PlatformException catch (e) {
      throw ProcessManagementException(
        'Failed to enumerate processes: ${e.message}',
      );
    }
  }

  /// Terminate a process by name.
  /// Returns true if process was found and terminated.
  Future<bool> terminateProcess(String processName) async {
    try {
      final bool result = await _platform.invokeMethod<bool>(
            'terminateProcess',
            {'name': processName},
          ) ??
          false;
      return result;
    } on PlatformException catch (e) {
      throw ProcessManagementException(
        'Failed to terminate process: ${e.message}',
      );
    }
  }

  /// Stream of process violation events (forbidden app detected).
  Stream<String> get violations {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String);
  }
}
