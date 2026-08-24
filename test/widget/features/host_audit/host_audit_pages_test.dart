import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/host_audit/domain/host_audit_types.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/notification_audit_bloc.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/notification_audit_event.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/notification_audit_state.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/violation_audit_bloc.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/violation_audit_event.dart';
import 'package:pte_app/features/host_audit/presentation/bloc/violation_audit_state.dart';
import 'package:pte_app/features/host_audit/presentation/pages/notification_audit_page.dart';
import 'package:pte_app/features/host_audit/presentation/pages/violation_audit_page.dart';

class _MockNotificationBloc
    extends MockBloc<NotificationAuditEvent, NotificationAuditState>
    implements NotificationAuditBloc {}

class _MockViolationBloc
    extends MockBloc<ViolationAuditBlocEvent, ViolationAuditState>
    implements ViolationAuditBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NotificationAuditRequested());
    registerFallbackValue(const ViolationAuditRequested('session-1'));
  });

  testWidgets('notification audit renders authoritative read-only fields', (
    tester,
  ) async {
    final bloc = _MockNotificationBloc();
    when(() => bloc.state).thenReturn(
      NotificationAuditLoaded([
        NotificationAudit(
          publicId: 'notification-1',
          recipientEmail: 'student@example.com',
          notificationType: 'SESSION_OPENED',
          subject: 'Session available',
          status: 'SENT',
          sentAt: DateTime.utc(2026, 7, 28, 1, 2, 3),
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationAuditBloc>.value(
          value: bloc,
          child: const NotificationAuditPage(),
        ),
      ),
    );

    expect(find.text('Session available'), findsOneWidget);
    expect(find.textContaining('student@example.com'), findsOneWidget);
    expect(find.textContaining('2026-07-28T01:02:03.000Z'), findsOneWidget);
    expect(find.text(AppStrings.edit), findsNothing);
    expect(find.text(AppStrings.delete), findsNothing);
  });

  testWidgets('violation audit preserves selectable integrity hash', (
    tester,
  ) async {
    final bloc = _MockViolationBloc();
    when(() => bloc.state).thenReturn(
      ViolationAuditLoaded([
        ViolationAuditEvent(
          publicId: 'violation-1',
          attemptPublicId: 'attempt-1',
          violationType: 'TAB_SWITCH',
          detail: 'Window focus changed',
          sequenceNo: 1,
          hash: 'abc123',
          detectedAt: DateTime.utc(2026, 7, 28, 1, 3, 4),
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ViolationAuditBloc>.value(
          value: bloc,
          child: const ViolationAuditPage(sessionPublicId: 'session-1'),
        ),
      ),
    );

    expect(find.text('abc123'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.textContaining('attempt-1'), findsOneWidget);
    expect(find.text(AppStrings.edit), findsNothing);
    expect(find.text(AppStrings.delete), findsNothing);
  });

  testWidgets('notification failure exposes retry without mutation actions', (
    tester,
  ) async {
    final bloc = _MockNotificationBloc();
    when(
      () => bloc.state,
    ).thenReturn(NotificationAuditFailure(Exception('offline')));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationAuditBloc>.value(
          value: bloc,
          child: const NotificationAuditPage(),
        ),
      ),
    );
    await tester.tap(find.text(AppStrings.retry));

    verify(() => bloc.add(const NotificationAuditRequested())).called(1);
    expect(find.text(AppStrings.edit), findsNothing);
  });

  testWidgets(
    'violation empty and failure states stay read-only and retryable',
    (tester) async {
      final emptyBloc = _MockViolationBloc();
      when(() => emptyBloc.state).thenReturn(const ViolationAuditEmpty());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ViolationAuditBloc>.value(
            value: emptyBloc,
            child: const ViolationAuditPage(sessionPublicId: 'session-1'),
          ),
        ),
      );
      expect(find.text(AppStrings.violationAuditEmpty), findsOneWidget);

      final failedBloc = _MockViolationBloc();
      when(
        () => failedBloc.state,
      ).thenReturn(ViolationAuditFailure(Exception('forbidden')));
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ViolationAuditBloc>.value(
            value: failedBloc,
            child: const ViolationAuditPage(sessionPublicId: 'session-1'),
          ),
        ),
      );
      await tester.tap(find.text(AppStrings.retry));

      final captured =
          verify(
                () => failedBloc.add(
                  captureAny(that: isA<ViolationAuditRequested>()),
                ),
              ).captured.single
              as ViolationAuditRequested;
      expect(captured.sessionPublicId, 'session-1');
      expect(find.text(AppStrings.delete), findsNothing);
    },
  );
}
