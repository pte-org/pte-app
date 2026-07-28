/// Build-time app configuration. Swap [gatewayBaseUrl] for a compile-time
/// env value when a staging/prod gateway exists — out of scope for
/// Milestone 1 (spec.md Assumptions).
class AppConfig {
  const AppConfig._();

  /// No `/api` suffix — every call site passes the full gateway-relative
  /// path (e.g. `/api/iam/auth/login`), so concatenation never
  /// double-prefixes it. See phase-01 Design Constraints.
  static const String gatewayBaseUrl = 'http://localhost:8080';

  /// Every gateway `Dio` instance must set these — an unbounded call can
  /// otherwise strand a caller (e.g. `AuthBloc` stuck in
  /// `AuthAuthenticating` forever) on a stalled connection (QUAL-102,
  /// Phase 1 quality gate).
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);
}
