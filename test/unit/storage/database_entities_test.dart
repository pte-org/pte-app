import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/storage/app_database.dart';

void main() {
  group('Drift Generated Entities and Companions', () {
    test('LocalViolation serialization, copyWith and companion conversion', () {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      final entity = LocalViolation(
        id: 1,
        clientEventId: 'evt-1',
        attemptPublicId: 'att-1',
        violationType: 'LOCKDOWN_FULLSCREEN_EXIT',
        severity: 'WARNING',
        timestamp: now,
        metadata: '{"key":"val"}',
        sent: false,
        terminal: false,
        terminalReason: null,
      );

      final json = entity.toJson();
      final fromJson = LocalViolation.fromJson(json);
      expect(fromJson.clientEventId, equals(entity.clientEventId));
      expect(fromJson.attemptPublicId, equals(entity.attemptPublicId));
      expect(fromJson.severity, equals(entity.severity));
      expect(fromJson.timestamp.millisecondsSinceEpoch, equals(entity.timestamp.millisecondsSinceEpoch));
      expect(entity.toString(), contains('LocalViolation('));

      final cols = entity.toColumns(false);
      expect(cols['id'], isNotNull);
      expect(cols['client_event_id'], isNotNull);

      final companion = entity.toCompanion(true);
      expect(companion.id.value, equals(1));
      expect(companion.clientEventId.value, equals('evt-1'));

      final modified = entity.copyWith(
        sent: true,
        terminal: true,
        terminalReason: const Value('Fatal error'),
      );
      expect(modified.sent, isTrue);
      expect(modified.terminal, isTrue);
      expect(modified.terminalReason, equals('Fatal error'));

      final compModified = entity.copyWithCompanion(
        const LocalViolationsTableCompanion(
          terminal: Value(true),
          terminalReason: Value('Companion reason'),
        ),
      );
      expect(compModified.terminal, isTrue);
      expect(compModified.terminalReason, equals('Companion reason'));

      const insertComp = LocalViolationsTableCompanion(
        clientEventId: Value('evt-new'),
        attemptPublicId: Value('att-new'),
        violationType: Value('PROCESS'),
        severity: Value('CRITICAL'),
        timestamp: Value.absent(),
      );
      expect(insertComp.toString(), contains('LocalViolationsTableCompanion('));
      expect(insertComp.toColumns(true), isNotNull);
    });

    test('AnswerOutbox serialization, copyWith and companion conversion', () {
      final nowMs = DateTime.utc(2026, 11, 4, 12, 0, 0).millisecondsSinceEpoch;
      final outbox = AnswerOutbox(
        attemptPublicId: 'att-10',
        pinnedItemPublicId: 'pin-10',
        payload: '{"answer":"A"}',
        status: 'PENDING',
        createdAt: nowMs,
        updatedAt: nowMs,
      );

      final json = outbox.toJson();
      final fromJson = AnswerOutbox.fromJson(json);
      expect(fromJson, equals(outbox));
      expect(fromJson.hashCode, equals(outbox.hashCode));
      expect(outbox.toString(), contains('AnswerOutbox('));

      final cols = outbox.toColumns(false);
      expect(cols['attempt_public_id'], isNotNull);

      final comp = outbox.toCompanion(true);
      expect(comp.attemptPublicId.value, equals('att-10'));

      final copied = outbox.copyWith(status: 'SENT');
      expect(copied.status, equals('SENT'));

      final companionCopied = outbox.copyWithCompanion(
        const AnswerOutboxTableCompanion(status: Value('ERROR')),
      );
      expect(companionCopied.status, equals('ERROR'));

      final insComp = AnswerOutboxTableCompanion.insert(
        attemptPublicId: 'att-ins',
        pinnedItemPublicId: 'pin-ins',
        payload: 'payload',
        status: 'PENDING',
        createdAt: nowMs,
        updatedAt: nowMs,
      );
      expect(insComp.toString(), contains('AnswerOutboxTableCompanion('));
    });

    test('PendingMediaUpload serialization, copyWith and companion conversion', () {
      final media = PendingMediaUpload(
        attemptPublicId: 'att-20',
        pinnedItemPublicId: 'pin-20',
        localFilePath: '/tmp/audio.wav',
        status: 'PENDING',
        cloudinaryApiKey: 'key',
        cloudinaryTimestamp: '12345678',
        cloudinaryUploadSignature: 'sig',
        cloudinaryFolder: 'folder',
        cloudinaryResourceType: 'video',
        cloudinaryPublicId: 'pub-id',
        cloudinaryAssetId: 'asset-id',
        cloudinarySecureUrl: 'https://cloudinary.com/audio.wav',
        cloudinaryFormat: 'wav',
        cloudinaryBytes: 1024,
        cloudinaryDurationSeconds: 12,
        cloudinaryVersion: 1,
        cloudinarySignature: 'verified-sig',
      );

      final json = media.toJson();
      final fromJson = PendingMediaUpload.fromJson(json);
      expect(fromJson, equals(media));
      expect(fromJson.hashCode, equals(media.hashCode));
      expect(media.toString(), contains('PendingMediaUpload('));

      final cols = media.toColumns(false);
      expect(cols['cloudinary_secure_url'], isNotNull);

      final comp = media.toCompanion(true);
      expect(comp.attemptPublicId.value, equals('att-20'));

      final copied = media.copyWith(
        status: 'COMPLETED',
        cloudinaryFormat: const Value('mp3'),
      );
      expect(copied.status, equals('COMPLETED'));
      expect(copied.cloudinaryFormat, equals('mp3'));

      final compCopied = media.copyWithCompanion(
        const PendingMediaUploadTableCompanion(status: Value('READY')),
      );
      expect(compCopied.status, equals('READY'));

      final insComp = PendingMediaUploadTableCompanion.insert(
        attemptPublicId: 'att-media',
        pinnedItemPublicId: 'pin-media',
        localFilePath: '/path',
        status: 'RECORDED',
      );
      expect(insComp.toString(), contains('PendingMediaUploadTableCompanion('));
    });
  });
}
