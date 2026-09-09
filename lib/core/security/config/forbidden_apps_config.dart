import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart' show rootBundle;

/// Single forbidden-app descriptor. Mirrors the platform-specific JSON
/// structure used by `services/scheduling`'s scheduling
/// `ForbiddenAppsConfig` (Phase 1 already defined a similar shape
/// server-side — this is the client twin, kept shaped the same so a
/// future server-sync path doesn't need a migration).
class ForbiddenApp {
  const ForbiddenApp({
    required this.name,
    required this.processName,
    required this.category,
  });

  final String name;

  /// `chrome.exe` on Windows, `Google Chrome` on macOS — exactly the
  /// string the OS-level process enumerator will return. Compare case
  /// insensitively, since Windows file system is case-insensitive.
  final String processName;
  final String category;

  factory ForbiddenApp.fromJson(Map<String, dynamic> json) {
    return ForbiddenApp(
      name: json['name'] as String,
      processName: json['processName'] as String,
      category: json['category'] as String,
    );
  }

  @override
  String toString() => '$name ($processName)';
}

/// All forbidden apps, packaged with the platform-keyed lists. The class
/// also acts as a loader: [load] reads the bundled
/// `assets/config/forbidden_apps.json` asset and returns a parsed
/// instance.
class ForbiddenAppsConfig {
  const ForbiddenAppsConfig({
    required this.windows,
    required this.macos,
  });

  /// Windows-side entries. Only populated for desktop-Windows builds —
  /// server-validated at [load] time so a mis-deployed asset still
  /// produces a sensible empty list (rather than crashing the whole
  /// lockdown flow on app start).
  final List<ForbiddenApp> windows;

  /// macOS-side entries. Empty list on every other platform so callers
  /// don't need to switch on `Platform.isMacOS` themselves.
  final List<ForbiddenApp> macos;

  /// Returns the entries applicable to the runtime platform, or an
  /// empty list for any other OS (mobile/web). `LockdownService`
  /// treats the empty list as "no enforcement" without needing a
  /// special-case branch.
  List<ForbiddenApp> getForCurrentPlatform() {
    if (Platform.isWindows) return windows;
    if (Platform.isMacOS) return macos;
    return const [];
  }

  /// Bundled-asset loader. Safe to call multiple times — the underlying
  /// asset bundle caches lookups, so it's cheap on repeat invocations.
  /// Tests can swap the loader via the [assetLoader] parameter.
  static Future<ForbiddenAppsConfig> load({
    Future<String> Function(String)? assetLoader,
  }) async {
    final loader = assetLoader ?? rootBundle.loadString;
    final jsonString = await loader('assets/config/forbidden_apps.json');
    return fromJsonString(jsonString);
  }

  /// Direct from-string constructor. Used by [load] and by tests that
  /// want to inject an inline JSON document.
  static ForbiddenAppsConfig fromJsonString(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'forbidden_apps.json must be an object with windows/macos arrays',
      );
    }
    return ForbiddenAppsConfig(
      windows: _parseList(decoded['windows']),
      macos: _parseList(decoded['macos']),
    );
  }

  static List<ForbiddenApp> _parseList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const FormatException(
        'forbidden_apps.json platform section must be an array',
      );
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ForbiddenApp.fromJson)
        .toList(growable: false);
  }
}
