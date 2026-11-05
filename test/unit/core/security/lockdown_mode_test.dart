import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/platform/lockdown_exception.dart';
import 'package:pte_app/core/security/lockdown_mode.dart';

void main() {
  group('LockdownMode', () {
    test('fromString parses valid values case-insensitively', () {
      expect(LockdownMode.fromString('none'), LockdownMode.none);
      expect(LockdownMode.fromString('NONE'), LockdownMode.none);
      expect(LockdownMode.fromString('  standard  '), LockdownMode.standard);
      expect(LockdownMode.fromString('STRICT'), LockdownMode.strict);
    });

    test('fromString throws LockdownPolicyException for unknown mode', () {
      expect(
        () => LockdownMode.fromString('unknown_mode'),
        throwsA(
          isA<LockdownPolicyException>().having(
            (e) => e.rawValue,
            'rawValue',
            'unknown_mode',
          ),
        ),
      );
    });

    test('LockdownPolicyException has readable toString', () {
      const ex = LockdownPolicyException('Invalid policy', 'foo');
      expect(ex.toString(), 'LockdownPolicyException(Invalid policy)');
      expect(ex.rawValue, 'foo');
    });
  });

  group('LockdownException hierarchy', () {
    test('all subtypes format toString with runtimeType and message', () {
      const e1 = FullscreenEnforcementException('fullscreen failed');
      expect(e1.toString(), 'FullscreenEnforcementException: fullscreen failed');
      expect(e1.message, 'fullscreen failed');

      const e2 = ExitGuardException('exit guard failed');
      expect(e2.toString(), 'ExitGuardException: exit guard failed');

      const e3 = ProcessManagementException('process error');
      expect(e3.toString(), 'ProcessManagementException: process error');

      const e4 = ClipboardException('clipboard error');
      expect(e4.toString(), 'ClipboardException: clipboard error');

      const e5 = ShortcutInterceptionException('shortcut error');
      expect(e5.toString(), 'ShortcutInterceptionException: shortcut error');
    });
  });
}

