import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pte_app/core/storage/dao/answer_outbox_dao.dart';
import 'package:pte_app/core/storage/dao/local_violation_dao.dart';
import 'package:pte_app/core/storage/dao/pending_media_upload_dao.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/storage/tables/answer_outbox_table.dart';
import 'package:pte_app/core/storage/tables/local_violations_table.dart';
import 'package:pte_app/core/storage/tables/pending_media_upload_table.dart';

part 'app_database.g.dart';

/// App-wide Drift/SQLite database. A single file under the platform's app
/// documents directory so buffered answers (the outbox's whole reason to
/// exist — see phase-02 Design Constraints) survive process death, not just
/// app backgrounding.
@DriftDatabase(
  tables: [AnswerOutboxTable, PendingMediaUploadTable, LocalViolationsTable],
  daos: [AnswerOutboxDao, PendingMediaUploadDao, LocalViolationDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // Schema version rolls forward every time a real table lands in the
  // app — `2 -> 3` adds LocalViolationsTable for Phase 4 lockdown
  // violations. Fresh databases skip the migration entirely; existing
  // installs run the additive schema migration below.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS '
        'ux_local_violations_client_event_id '
        'ON local_violations_table (client_event_id)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        // LocalViolationsTable is purely additive — no backfill needed.
        // The new table is empty on this upgrade path; future persisted rows
        // still pass through the DAO's strict compatibility checks.
        await m.createTable(localViolationsTable);
      }
      if (from < 4) {
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryApiKey,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryTimestamp,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryUploadSignature,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryFolder,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryResourceType,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryPublicId,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryAssetId,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinarySecureUrl,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryFormat,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryBytes,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryDurationSeconds,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinaryVersion,
        );
        await m.addColumn(
          pendingMediaUploadTable,
          pendingMediaUploadTable.cloudinarySignature,
        );
      }
      if (from >= 3 && from < 5) {
        // SQLite needs a temporary SQL default to add this non-null column to
        // an existing table. The old rows are backfilled before uniqueness is
        // enforced below.
        await m.addColumn(
          localViolationsTable,
          localViolationsTable.clientEventId,
        );
        await m.addColumn(localViolationsTable, localViolationsTable.terminal);
        await m.addColumn(
          localViolationsTable,
          localViolationsTable.terminalReason,
        );
      }
      if (from < 5) {
        final legacyRows = await customSelect(
          'SELECT id, client_event_id FROM local_violations_table',
        ).get();
        for (final row in legacyRows) {
          final clientEventId = row.data['client_event_id'];
          if (clientEventId == null || clientEventId.toString().isEmpty) {
            await customStatement(
              'UPDATE local_violations_table '
              'SET client_event_id = ? WHERE id = ?',
              [newClientEventId(), row.data['id']],
            );
          }
        }
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS '
          'ux_local_violations_client_event_id '
          'ON local_violations_table (client_event_id)',
        );
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'pte_app.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
