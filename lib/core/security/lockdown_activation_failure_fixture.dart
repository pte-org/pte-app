import 'package:pte_app/core/platform/lockdown_exception.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';

/// Compile-time-only switch for the Phase 5 release gate. It is intentionally
/// false unless a non-distributable validation artifact opts in explicitly.
const bool lockdownActivationFailureFixtureEnabled = bool.fromEnvironment(
  'PTE_LOCKDOWN_ACTIVATION_FAILURE_FIXTURE',
  defaultValue: false,
);

/// Replaces the real window channel only in the controlled failure artifact.
/// The exception is raised before the native fullscreen call so the release
/// path can prove that task rendering is blocked and retry remains available.
class LockdownActivationFailureWindowManager extends WindowManagerChannel {
  const LockdownActivationFailureWindowManager();

  @override
  Future<void> enforceFullscreen() async {
    throw const FullscreenEnforcementException(
      'Controlled Phase 5 activation failure fixture',
    );
  }

  @override
  Stream<String> get violations => const Stream<String>.empty();
}
