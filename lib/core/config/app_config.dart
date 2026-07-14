/// Environment/flavor configuration for `aptis-app`.
///
/// Phase 1 placeholder: fields are stubbed with safe defaults. Phase 3
/// (Core/Network) fills in the real API base URL, timeouts, and any
/// per-environment overrides once the Dio client is wired.
class AppConfig {
  const AppConfig({
    this.apiBaseUrl = 'https://api.aptis.example.com/api/v1',
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 60),
  });

  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
