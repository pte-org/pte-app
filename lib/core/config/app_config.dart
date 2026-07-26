/// Build-time app configuration. Swap [gatewayBaseUrl] for a compile-time
/// env value when a staging/prod gateway exists — out of scope for
/// Milestone 1 (spec.md Assumptions).
class AppConfig {
  const AppConfig._();

  /// No `/api` suffix — every call site passes the full gateway-relative
  /// path (e.g. `/api/iam/auth/login`), so concatenation never
  /// double-prefixes it. See phase-01 Design Constraints.
  static const String gatewayBaseUrl = 'http://localhost:8080';
}
