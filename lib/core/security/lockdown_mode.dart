/// The level of exam lockdown a backend exam-policy demands.
///
/// Backend mapping (Phase 1): PRACTICE → none, MOCK_TEST → standard,
/// REAL_EXAM → strict. This enum drives the [LockdownService] activation
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

  /// Parses the backend string. Tolerant of legacy casing (the existing
  /// scheduling DTOs use `LockdownMode.valueOf` which is case-sensitive
  /// server-side, but the wire format is always uppercase on disk).
  static LockdownMode fromString(String value) {
    final normalized = value.trim().toLowerCase();
    return LockdownMode.values.firstWhere(
      (mode) => mode.name == normalized,
      orElse: () => LockdownMode.none,
    );
  }
}
