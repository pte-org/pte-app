import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/widgets/primary_button.dart';
import 'package:pte_app/features/scheduling/domain/session_types.dart';
import 'package:pte_app/features/scheduling/domain/usecases/create_session.dart';
import 'package:pte_app/features/scheduling/domain/usecases/load_session.dart';
import 'package:pte_app/features/scheduling/domain/usecases/load_snapshot_options.dart';
import 'package:pte_app/features/scheduling/domain/usecases/update_session_composition.dart';
import 'package:pte_app/features/scheduling/domain/usecases/update_session_status.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_create_bloc.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_detail_bloc.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/session_detail_event.dart';
import 'package:pte_app/features/scheduling/presentation/pages/session_create_page.dart';
import 'package:pte_app/features/scheduling/presentation/pages/session_detail_page.dart';

class _MockCreateSession extends Mock implements CreateSession {}

class _MockLoadSession extends Mock implements LoadSession {}

class _MockLoadSnapshotOptions extends Mock implements LoadSnapshotOptions {}

class _MockUpdateComposition extends Mock implements UpdateSessionComposition {}

class _MockOpenSession extends Mock implements OpenSession {}

class _MockCloseSession extends Mock implements CloseSession {}

final scheduledSession = ExamSession(
  publicId: 'session-1',
  name: 'Mock exam',
  tenantId: 'tenant-1',
  snapshotPublicId: 'snap-1',
  opensAt: DateTime.utc(2026, 7, 29, 8),
  closesAt: DateTime.utc(2026, 7, 29, 10),
  status: SessionStatus.scheduled,
  composition: const [],
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      CreateSessionInput(
        name: 'fallback',
        snapshotPublicId: 'snap',
        opensAt: DateTime.utc(2026, 7, 29),
        closesAt: DateTime.utc(2026, 7, 30),
      ),
    );
    registerFallbackValue(SetCompositionInput(items: const []));
  });

  testWidgets('create page submits backend-aligned session fields', (
    tester,
  ) async {
    final create = _MockCreateSession();
    when(() => create(any())).thenAnswer((_) async => scheduledSession);
    final bloc = SessionCreateBloc(
      createSession: create,
      clock: () => DateTime.utc(2026, 7, 28),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const SessionCreatePage()),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('session-name')),
      'Mock exam',
    );
    await tester.enterText(find.byKey(const ValueKey('snapshot-id')), 'snap-1');
    await tester.enterText(
      find.byKey(const ValueKey('opens-at')),
      '2026-07-29T08:00:00Z',
    );
    await tester.enterText(
      find.byKey(const ValueKey('closes-at')),
      '2026-07-29T10:00:00Z',
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.pump();

    final input =
        verify(() => create(captureAny())).captured.single
            as CreateSessionInput;
    expect(input.snapshotPublicId, 'snap-1');
    expect(input.opensAt, DateTime.utc(2026, 7, 29, 8));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'detail derives practice composition and gates lifecycle action',
    (tester) async {
      final load = _MockLoadSession();
      final loadOptions = _MockLoadSnapshotOptions();
      final update = _MockUpdateComposition();
      final open = _MockOpenSession();
      final close = _MockCloseSession();
      when(() => load('session-1')).thenAnswer((_) async => scheduledSession);
      when(() => loadOptions('snap-1')).thenAnswer(
        (_) async => const [
          SnapshotTaskOption(
            taskType: 'READ_ALOUD',
            section: 'SPEAKING',
            title: 'Read aloud',
          ),
          SnapshotTaskOption(
            taskType: 'WRITE_ESSAY',
            section: 'WRITING',
            title: 'Essay',
          ),
        ],
      );
      when(
        () => update('session-1', any()),
      ).thenAnswer((_) async => scheduledSession);
      final bloc = SessionDetailBloc(
        loadSession: load,
        loadSnapshotOptions: loadOptions,
        updateComposition: update,
        openSession: open,
        closeSession: close,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const SessionDetailPage(isAdmin: true),
          ),
        ),
      );
      bloc.add(const SessionDetailRequested('session-1'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.openSession), findsOneWidget);
      expect(find.text(AppStrings.closeSession), findsNothing);
      expect(find.text(AppStrings.manageParticipants), findsOneWidget);
      await tester.tap(find.text('Read aloud'));
      await tester.tap(find.text(AppStrings.saveComposition));
      await tester.pumpAndSettle();

      final input =
          verify(() => update('session-1', captureAny())).captured.single
              as SetCompositionInput;
      expect(input.items.single.taskType, 'READ_ALOUD');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
