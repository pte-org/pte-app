import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/security/config/forbidden_apps_config.dart';

void main() {
  group('ForbiddenAppsConfig.fromJsonString', () {
    test('parses both windows and macos arrays', () {
      const json = '''
{
  "windows": [
    {"name": "Chrome", "processName": "chrome.exe", "category": "browser"}
  ],
  "macos": [
    {"name": "Safari", "processName": "Safari", "category": "browser"}
  ]
}
''';
      final config = ForbiddenAppsConfig.fromJsonString(json);

      expect(config.windows, hasLength(1));
      expect(config.windows.first.processName, 'chrome.exe');
      expect(config.macos.single.processName, 'Safari');
    });

    test('throws FormatException when the root is not an object', () {
      expect(
        () => ForbiddenAppsConfig.fromJsonString('[]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when a platform list is not an array', () {
      const json = '''
{"windows": "not-an-array", "macos": []}
''';
      expect(
        () => ForbiddenAppsConfig.fromJsonString(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('treats missing platform sections as empty', () {
      const json = '{"windows": []}';
      final config = ForbiddenAppsConfig.fromJsonString(json);
      expect(config.windows, isEmpty);
      expect(config.macos, isEmpty);
    });
  });
}
