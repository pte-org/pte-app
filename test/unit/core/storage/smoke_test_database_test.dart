import 'dart:io';

import 'package:aptis_app/core/storage/smoke_test_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'drift native SQLite opens, writes, and reads a row on this platform without sqlite3_flutter_libs',
    () async {
      final dir = await Directory.systemTemp.createTemp('drift_smoke_');
      final dbFile = p.join(dir.path, 'smoke.sqlite');
      final db = SmokeTestDatabase(SmokeTestDatabase.openAt(dbFile));

      await db.into(db.smokeTestRows).insert(SmokeTestRowsCompanion.insert(value: 'ok'));
      final rows = await db.select(db.smokeTestRows).get();

      expect(rows, hasLength(1));
      expect(rows.single.value, 'ok');

      await db.close();
      await dir.delete(recursive: true);
    },
  );
}
