import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/platform/clipboard_monitor_channel.dart';
import 'package:pte_app/core/platform/lockdown_exception.dart';
import 'package:pte_app/core/platform/process_manager_channel.dart';
import 'package:pte_app/core/platform/shortcut_interceptor_channel.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('WindowManagerChannel', () {
    const channel = WindowManagerChannel();
    const platform = MethodChannel('com.pte.lockdown/window');

    test('enforceFullscreen succeeds and handles PlatformException', () async {
      messenger.setMockMethodCallHandler(platform, (call) async {
        if (call.method == 'enforceFullscreen') return null;
        throw PlatformException(code: 'ERROR', message: 'fullscreen fail');
      });

      await expectLater(channel.enforceFullscreen(), completes);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw PlatformException(code: 'ERR', message: 'enforce rejected');
      });

      await expectLater(
        channel.enforceFullscreen(),
        throwsA(isA<FullscreenEnforcementException>()),
      );
    });

    test('exitFullscreen succeeds and handles PlatformException', () async {
      messenger.setMockMethodCallHandler(platform, (call) async => null);
      await expectLater(channel.exitFullscreen(), completes);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw PlatformException(code: 'ERR', message: 'exit rejected');
      });

      await expectLater(
        channel.exitFullscreen(),
        throwsA(isA<FullscreenEnforcementException>()),
      );
    });

    test('setExitGuardActive succeeds and handles PlatformException / MissingPluginException', () async {
      messenger.setMockMethodCallHandler(platform, (call) async => null);
      await expectLater(channel.setExitGuardActive(true), completes);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw MissingPluginException();
      });
      await expectLater(channel.setExitGuardActive(true), completes);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw PlatformException(code: 'ERR', message: 'guard error');
      });
      await expectLater(
        channel.setExitGuardActive(true),
        throwsA(isA<ExitGuardException>()),
      );
    });

    test('setExitAllowed succeeds and handles PlatformException', () async {
      messenger.setMockMethodCallHandler(platform, (call) async => null);
      await expectLater(channel.setExitAllowed(true), completes);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw MissingPluginException();
      });
      await expectLater(channel.setExitAllowed(false), completes);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw PlatformException(code: 'ERR', message: 'allow error');
      });
      await expectLater(
        channel.setExitAllowed(false),
        throwsA(isA<ExitGuardException>()),
      );
    });
  });

  group('ProcessManagerChannel', () {
    const channel = ProcessManagerChannel();
    const platform = MethodChannel('com.pte.lockdown/process');

    test('getRunningProcesses returns list and handles PlatformException', () async {
      messenger.setMockMethodCallHandler(platform, (call) async {
        return ['pte_app.exe', 'explorer.exe'];
      });

      final list = await channel.getRunningProcesses();
      expect(list, equals(['pte_app.exe', 'explorer.exe']));

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw PlatformException(code: 'ERR', message: 'enum failed');
      });

      await expectLater(
        channel.getRunningProcesses(),
        throwsA(isA<ProcessManagementException>()),
      );
    });

    test('terminateProcess returns boolean and handles PlatformException', () async {
      messenger.setMockMethodCallHandler(platform, (call) async => true);
      final killed = await channel.terminateProcess('forbidden.exe');
      expect(killed, isTrue);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw PlatformException(code: 'ERR', message: 'kill failed');
      });

      await expectLater(
        channel.terminateProcess('forbidden.exe'),
        throwsA(isA<ProcessManagementException>()),
      );
    });
  });

  group('ClipboardMonitorChannel', () {
    const channel = ClipboardMonitorChannel();
    const platform = MethodChannel('com.pte.lockdown/clipboard');

    test('blockExternalPaste, clearClipboard, and unblock succeed and map exceptions', () async {
      messenger.setMockMethodCallHandler(platform, (call) async => null);

      await expectLater(channel.blockExternalPaste(), completes);
      await expectLater(channel.clearClipboard(), completes);
      await expectLater(channel.unblock(), completes);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw PlatformException(code: 'ERR', message: 'clipboard error');
      });

      await expectLater(channel.blockExternalPaste(), throwsA(isA<ClipboardException>()));
      await expectLater(channel.clearClipboard(), throwsA(isA<ClipboardException>()));
      await expectLater(channel.unblock(), throwsA(isA<ClipboardException>()));
    });
  });

  group('ShortcutInterceptorChannel', () {
    const channel = ShortcutInterceptorChannel();
    const platform = MethodChannel('com.pte.lockdown/shortcuts');

    test('blockSystemShortcuts and unblock succeed and map exceptions', () async {
      messenger.setMockMethodCallHandler(platform, (call) async => null);

      await expectLater(channel.blockSystemShortcuts(), completes);
      await expectLater(channel.unblock(), completes);

      messenger.setMockMethodCallHandler(platform, (call) async {
        throw PlatformException(code: 'ERR', message: 'shortcut error');
      });

      await expectLater(channel.blockSystemShortcuts(), throwsA(isA<ShortcutInterceptionException>()));
      await expectLater(channel.unblock(), throwsA(isA<ShortcutInterceptionException>()));
    });
  });
}

