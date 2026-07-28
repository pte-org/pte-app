import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/host_audit/domain/host_audit_types.dart';
import 'package:pte_app/features/host_audit/domain/usecases/load_host_audit.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/notification_audit_bloc.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/notification_audit_event.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/notification_audit_state.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/violation_audit_bloc.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/violation_audit_event.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/violation_audit_state.dart';

class _MockLoadNotifications extends Mock implements LoadNotifications {}

class _MockLoadViolations extends Mock implements LoadViolations {}

void main() {
  test('notification bloc exposes empty response', () async {
    final load = _MockLoadNotifications();
    when(load.call).thenAnswer((_) async => const []);
    final bloc = NotificationAuditBloc(loadNotifications: load)
      ..add(const NotificationAuditRequested());

    expect(
      await bloc.stream.firstWhere((state) => state is NotificationAuditEmpty),
      isA<NotificationAuditEmpty>(),
    );
    await bloc.close();
  });

  blocTest<ViolationAuditBloc, ViolationAuditState>(
    'violation bloc loads immutable ordered response',
    setUp: () {
      final load = _MockLoadViolations();
      when(() => load('session-1')).thenAnswer(
        (_) async => [
          ViolationAuditEvent(
            publicId: 'violation-1',
            attemptPublicId: 'attempt-1',
            violationType: 'TAB_SWITCH',
            detail: 'Focus changed',
            sequenceNo: 1,
            hash: 'abc',
            detectedAt: DateTime.utc(2026, 7, 28),
          ),
        ],
      );
    },
    build: () {
      final load = _MockLoadViolations();
      when(() => load('session-1')).thenAnswer(
        (_) async => [
          ViolationAuditEvent(
            publicId: 'violation-1',
            attemptPublicId: 'attempt-1',
            violationType: 'TAB_SWITCH',
            detail: 'Focus changed',
            sequenceNo: 1,
            hash: 'abc',
            detectedAt: DateTime.utc(2026, 7, 28),
          ),
        ],
      );
      return ViolationAuditBloc(loadViolations: load);
    },
    act: (bloc) => bloc.add(const ViolationAuditRequested('session-1')),
    expect: () => [
      isA<ViolationAuditLoading>(),
      isA<ViolationAuditLoaded>().having(
        (state) => state.items.single.hash,
        'hash',
        'abc',
      ),
    ],
  );
}
