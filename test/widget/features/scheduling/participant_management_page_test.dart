import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/host_users/domain/host_user.dart';
import 'package:pte_app/features/scheduling/presentation/pages/participant_management_page.dart';

void main() {
  testWidgets('admin sees role-filtered enrollment and proctor actions', (
    tester,
  ) async {
    final users = [
      HostUser(
        publicId: 'student-1',
        email: 'student@example.com',
        fullName: 'Student One',
        tenantId: 'tenant-1',
        status: 'ACTIVE',
        roles: const ['STUDENT'],
      ),
      HostUser(
        publicId: 'proctor-1',
        email: 'proctor@example.com',
        fullName: 'Proctor One',
        tenantId: 'tenant-1',
        status: 'ACTIVE',
        roles: const ['PROCTOR'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ParticipantManagementPage(
          sessionPublicId: 'session-1',
          loadUsers: () async => users,
          onEnroll: (_, _) async {},
          onAssign: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student One'), findsOneWidget);
    expect(find.text('Proctor One'), findsOneWidget);
    expect(find.text(AppStrings.enrollStudent), findsOneWidget);
    expect(find.text(AppStrings.assignProctor), findsOneWidget);
  });

  testWidgets('enrollment requires confirmation before command', (
    tester,
  ) async {
    var calls = 0;
    final student = HostUser(
      publicId: 'student-1',
      email: 'student@example.com',
      fullName: 'Student One',
      tenantId: 'tenant-1',
      status: 'ACTIVE',
      roles: const ['STUDENT'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ParticipantManagementPage(
          sessionPublicId: 'session-1',
          loadUsers: () async => [student],
          onEnroll: (_, _) async => calls++,
          onAssign: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.enrollStudent));
    await tester.pump();
    expect(calls, 0);
    expect(find.text(AppStrings.participantConfirmation), findsOneWidget);
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}
