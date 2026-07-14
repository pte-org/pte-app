import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dao/answer_outbox_dao.dart';
import 'tables/answer_outbox_table.dart';

part 'drift_database.g.dart';

/// App-wide Drift database. Pass an explicit [executor] in tests to point
/// at an in-memory or temp-file database instead of the real app-documents
/// location used in production (see [_openConnection]).
@DriftDatabase(tables: [AnswerOutboxTable], daos: [AnswerOutboxDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'aptis_app.sqlite'));
      return NativeDatabase.createInBackground(
        file,
        setup: (db) => db.execute('PRAGMA journal_mode=WAL;'),
      );
    });
  }
}
