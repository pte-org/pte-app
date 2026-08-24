/// Stable dependency-registration entry point for the Host workspace.
///
/// Phase 0 contains only presentation and pure access-policy code, so it has no
/// runtime dependencies to register yet. Later Host features can extend this
/// function without changing application bootstrap structure.
void setupHostConsoleModule() {}
