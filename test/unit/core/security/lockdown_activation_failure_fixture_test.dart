import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/platform/lockdown_exception.dart';
import 'package:pte_app/core/security/lockdown_activation_failure_fixture.dart';

void main() {
  test('controlled window fixture fails before native fullscreen', () async {
    const window = LockdownActivationFailureWindowManager();

    await expectLater(
      window.enforceFullscreen(),
      throwsA(isA<FullscreenEnforcementException>()),
    );
    expect(window.violations, emitsDone);
  });
}
