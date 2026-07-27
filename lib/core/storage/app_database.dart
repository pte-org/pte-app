import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dao/answer_outbox_dao.dart';
import 'tables/answer_outbox_table.dart';

part 'app_database.g.dart';

/// App-wide Drift/SQLite database. A single file under the platform's app
/// documents directory so buffered answers (the outbox's whole reason to
/// exist — see phase-02 Design Constraints) survive process death, not just
/// app backgrounding.
@DriftDatabase(tables: [AnswerOutboxTable], daos: [AnswerOutboxDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'pte_app.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
