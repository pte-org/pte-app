import 'package:flutter/foundation.dart';

/// Build-time app configuration. Swap [gatewayBaseUrl] for a compile-time
/// env value when a staging/prod gateway exists — out of scope for
/// Milestone 1 (spec.md Assumptions).
class AppConfig {
  const AppConfig._();

  /// No `/api` suffix — every call site passes the full gateway-relative
  /// path (e.g. `/api/iam/auth/login`), so concatenation never
  /// double-prefixes it. See phase-01 Design Constraints.
  ///
  /// The default is the API gateway's own port (`8080`), not an individual
  /// backend service's raw port. The dev-only mock may intentionally override
  /// this to the exam-delivery service port (`8085`) together with
  /// [examAttemptsPath].
  static const String gatewayBaseUrl = String.fromEnvironment(
    'PTE_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Full path prefix for attempt lifecycle/audio calls. The mock API uses
  /// `/api/exam-delivery/mock-attempts`; the default is the real route.
  static const String examAttemptsPath = String.fromEnvironment(
    'PTE_EXAM_ATTEMPTS_PATH',
    defaultValue: '/api/exam-delivery/attempts',
  );

  /// Dev-only: answer every gateway/upload/live-proctor call from the
  /// in-memory mock backend (`lib/dev/mock_backend/`) instead of pte-api, so
  /// the full app can be UI-tested offline. Enable with
  /// `--dart-define=MOCK_BACKEND=true`; always off in release builds.
  static const bool useMockBackend =
      bool.fromEnvironment('MOCK_BACKEND') && !kReleaseMode;

  /// Every gateway `Dio` instance must set these — an unbounded call can
  /// otherwise strand a caller (e.g. `AuthBloc` stuck in
  /// `AuthAuthenticating` forever) on a stalled connection (QUAL-102,
  /// Phase 1 quality gate).
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);
}
