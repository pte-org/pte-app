import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/core/security/violation_reporter.dart';
import 'package:pte_app/core/storage/app_database.dart';

class _MockApiClient extends Mock implements ApiClient {}

ViolationEvent _makeEvent({
  String id = 'event-terminal-1',
  ViolationType type = ViolationType.fullscreenExit,
  ViolationSeverity severity = ViolationSeverity.warning,
}) {
  return ViolationEvent(
    clientEventId: id,
    attemptPublicId: 'attempt-1',
    type: type,
    severity: severity,
    timestamp: DateTime.utc(2026, 11, 4),
  );
}

void main() {
  late AppDatabase db;
  late _MockApiClient api;
  late ViolationReporter reporter;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _MockApiClient();
    reporter = ViolationReporter(
      localDao: db.localViolationDao,
      apiClient: api,
      logger: Logger(printer: PrettyPrinter(methodCount: 0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ViolationReporter terminal errors & cleanup', () {
    test('reportViolation marks row terminal when DioException status is 400', () async {
      when(
        () => api.post<void>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/violations'),
          response: Response(
            requestOptions: RequestOptions(path: '/violations'),
            statusCode: 400,
          ),
        ),
      );

      final event = _makeEvent(id: 'client-terminal-400');
      await reporter.reportViolation(event);

      final rows = await db.localViolationDao.getAllForAttempt('attempt-1');
      expect(rows, hasLength(1));
      expect(rows.single.terminal, isTrue);
      expect(rows.single.sent, isFalse);
    });

    test('reportViolation marks row terminal when DioException status is 404', () async {
      when(
        () => api.post<void>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/violations'),
          response: Response(
            requestOptions: RequestOptions(path: '/violations'),
            statusCode: 404,
          ),
        ),
      );

      final event = _makeEvent(id: 'client-terminal-404');
      await reporter.reportViolation(event);

      final rows = await db.localViolationDao.getAllForAttempt('attempt-1');
      expect(rows, hasLength(1));
      expect(rows.single.terminal, isTrue);
    });

    test('retryUnsent marks row terminal when retry encounters DioException 422', () async {
      reporter.debugSetRetryCooldown(Duration.zero);
      await db.localViolationDao.insert(_makeEvent(id: 'retry-422'));

      when(
        () => api.post<void>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/violations'),
          response: Response(
            requestOptions: RequestOptions(path: '/violations'),
            statusCode: 422,
          ),
        ),
      );

      await reporter.retryUnsent();

      final rows = await db.localViolationDao.getAllForAttempt('attempt-1');
      expect(rows.single.terminal, isTrue);
    });

    test('retryUnsent marks row terminal when retry encounters ApiException', () async {
      reporter.debugSetRetryCooldown(Duration.zero);
      await db.localViolationDao.insert(_makeEvent(id: 'retry-api-ex'));

      when(
        () => api.post<void>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        const ConflictException('Duplicate report rejected permanently'),
      );

      await reporter.retryUnsent();

      final rows = await db.localViolationDao.getAllForAttempt('attempt-1');
      expect(rows.single.terminal, isTrue);
    });

    test('retryUnsent halts on non-terminal ApiException (e.g. server error)', () async {
      reporter.debugSetRetryCooldown(Duration.zero);
      await db.localViolationDao.insert(_makeEvent(id: 'retry-api-500'));

      when(
        () => api.post<void>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        const UnknownApiException('Backend internal error'),
      );

      await reporter.retryUnsent();

      final rows = await db.localViolationDao.getAllForAttempt('attempt-1');
      expect(rows.single.terminal, isFalse);
      expect(rows.single.sent, isFalse);
    });

    test('retryUnsent marks row terminal on UnknownViolationTypeException', () async {
      reporter.debugSetRetryCooldown(Duration.zero);
      await db.customStatement(
        'INSERT INTO local_violations_table '
        '(client_event_id, attempt_public_id, violation_type, severity, timestamp, sent, terminal) '
        'VALUES (?, ?, ?, ?, ?, 0, 0)',
        [
          'corrupted-type-1',
          'attempt-1',
          'NON_EXISTENT_FUTURE_VIOLATION_TYPE',
          'WARNING',
          DateTime.now().millisecondsSinceEpoch,
        ],
      );

      await reporter.retryUnsent();

      final rows = await db.localViolationDao.getAllForAttempt('attempt-1');
      final corrupted = rows.firstWhere((r) => r.clientEventId == 'corrupted-type-1');
      expect(corrupted.terminal, isTrue);
    });

    test('cleanupOld deletes sent rows older than duration', () async {
      final oldId = await db.localViolationDao.insert(
        ViolationEvent(
          clientEventId: 'old-event',
          attemptPublicId: 'attempt-old',
          type: ViolationType.fullscreenExit,
          severity: ViolationSeverity.warning,
          timestamp: DateTime.now().subtract(const Duration(days: 10)),
        ),
      );
      await db.localViolationDao.markSent(oldId);

      final recentId = await db.localViolationDao.insert(
        ViolationEvent(
          clientEventId: 'recent-event',
          attemptPublicId: 'attempt-recent',
          type: ViolationType.fullscreenExit,
          severity: ViolationSeverity.warning,
          timestamp: DateTime.now(),
        ),
      );
      await db.localViolationDao.markSent(recentId);

      await reporter.cleanupOld(olderThan: const Duration(days: 7));

      final oldRows = await db.localViolationDao.getAllForAttempt('attempt-old');
      final recentRows = await db.localViolationDao.getAllForAttempt('attempt-recent');

      expect(oldRows, isEmpty);
      expect(recentRows, hasLength(1));
    });

    test('debugSetRetryOverride executes custom driver', () async {
      var customDriverRan = false;
      reporter.debugSetRetryOverride(() async {
        customDriverRan = true;
      });

      await reporter.retryUnsent();
      expect(customDriverRan, isTrue);
    });
  });
}
