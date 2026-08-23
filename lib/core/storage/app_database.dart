import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/storage/tables/answer_outbox_table.dart';
import 'package:pte_app/core/storage/tables/pending_media_upload_table.dart';

part 'app_database.g.dart';

/// App-wide Drift/SQLite database. A single file under the platform's app
/// documents directory so buffered answers (the outbox's whole reason to
/// exist — see phase-02 Design Constraints) survive process death, not just
/// app backgrounding.
@DriftDatabase(
  tables: [AnswerOutboxTable, PendingMediaUploadTable],
  daos: [AnswerOutboxDao, PendingMediaUploadDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // Bumped from 1 -> 2 by Phase 6's PendingMediaUploadTable addition. No
  // real installs predate this (pre-release), so no migration is defined —
  // Drift creates the full current schema on first open regardless of this
  // number for a fresh database file.
  @override
  int get schemaVersion => 2;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'pte_app.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
