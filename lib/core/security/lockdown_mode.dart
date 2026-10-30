/// The level of exam lockdown a backend exam-policy demands.
///
/// Parsed from the server-pinned `lockdownMode` (`NONE` / `STANDARD` /
/// `STRICT`). This enum drives the [LockdownService] activation
/// flow: `none` skips every enforcement step, `standard` enforces but
/// emits violations at warning severity, `strict` enforces AND
/// terminates forbidden apps on activation.
enum LockdownMode {
  /// No lockdown. Activation is a no-op; deactivation is also safe to
  /// call for symmetry with the other two modes.
  none,

  /// Lockdown with warning-only reporting. Block shortcuts / clipboard
  /// / fullscreen, but do NOT terminate running forbidden apps. Each
  /// violation is recorded at warning severity.
  standard,

  /// Full enforcement. Same as standard plus forbidden-app termination,
  /// and every violation recorded at critical severity.
  strict;

  /// Parses a server-pinned lockdown policy without inventing a fallback.
  ///
  /// A missing or unknown policy is a contract failure for a new attempt. It
  /// must not become [LockdownMode.none], because that would turn malformed
  /// policy data into an accidental bypass of the security contract.
  static LockdownMode fromString(String value) {
    final normalized = value.trim().toLowerCase();
    for (final mode in LockdownMode.values) {
      if (mode.name == normalized) return mode;
    }
    throw LockdownPolicyException('Unknown lockdown mode: $value', value);
  }
}

/// Raised when an attempt response does not contain a usable pinned policy.
///
/// This is intentionally separate from [LockdownActivationException]: the
/// former means the server contract is unsafe/invalid, while the latter means
/// a valid policy could not be installed on the device.
class LockdownPolicyException implements Exception {
  const LockdownPolicyException(this.message, [this.rawValue]);

  final String message;
  final String? rawValue;

  @override
  String toString() => 'LockdownPolicyException($message)';
}
