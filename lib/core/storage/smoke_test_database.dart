import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'smoke_test_database.g.dart';

/// Throwaway table for Phase 0's desktop (Windows) native-SQLite smoke
/// check — delete this file once Phase 2 builds the real outbox schema and
/// this determination has been recorded in plan.md.
class SmokeTestRows extends Table {
  TextColumn get value => text()();
}

@DriftDatabase(tables: [SmokeTestRows])
class SmokeTestDatabase extends _$SmokeTestDatabase {
  SmokeTestDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor openAt(String path) => NativeDatabase(File(path));
}
