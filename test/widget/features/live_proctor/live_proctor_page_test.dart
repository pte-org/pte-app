import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/features/live_proctor/domain/live_proctor_types.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_bloc.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_event.dart';
import 'package:pte_app/features/live_proctor/presentation/bloc/live_proctor_state.dart';
import 'package:pte_app/features/live_proctor/presentation/pages/live_proctor_page.dart';

class _MockLiveProctorBloc extends MockBloc<LiveProctorEvent, LiveProctorState>
    implements LiveProctorBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ViolationFlagRequested(
        attemptPublicId: 'fallback',
        violationType: ViolationType.other,
      ),
    );
  });

  Widget subject({required bool canControl, bool sessionOpened = false}) {
    final bloc = _MockLiveProctorBloc();
    whenListen(
      bloc,
      const Stream<LiveProctorState>.empty(),
      initialState: LiveProctorState(
        status: LiveProctorStatus.connected,
        canControl: canControl,
        proctorSession: sessionOpened
            ? ProctorSession(
                publicId: 'proctor-session-1',
                sessionPublicId: 'session-1',
                status: 'ACTIVE',
                openedAt: DateTime.utc(2026, 7, 28),
              )
            : null,
      ),
    );
    addTearDown(bloc.close);
    return MaterialApp(
      home: BlocProvider<LiveProctorBloc>.value(
        value: bloc,
        child: LiveProctorPage(canControl: canControl),
      ),
    );
  }

  testWidgets('HOST_ADMIN view is read-only', (tester) async {
    await tester.pumpWidget(subject(canControl: false));

    expect(find.text(AppStrings.liveReadOnlyNotice), findsOneWidget);
    expect(find.text(AppStrings.liveForceSubmit), findsNothing);
    expect(find.text(AppStrings.liveFlagViolation), findsNothing);
  });

  testWidgets('PROCTOR view exposes guarded command controls', (tester) async {
    await tester.pumpWidget(subject(canControl: true));

    expect(find.text(AppStrings.liveReadOnlyNotice), findsNothing);
    expect(find.text(AppStrings.liveForceSubmit), findsOneWidget);
    expect(find.text(AppStrings.liveFlagViolation), findsOneWidget);
  });

  testWidgets('violation is dispatched only after confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(subject(canControl: true, sessionOpened: true));
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.liveAttemptIdLabel),
      'attempt-1',
    );
    await tester.tap(find.text(AppStrings.liveFlagViolation));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.liveViolationConfirmation), findsOneWidget);
    final bloc = BlocProvider.of<LiveProctorBloc>(
      tester.element(find.byType(LiveProctorPage)),
    );
    verifyNever(() => bloc.add(any()));

    await tester.tap(find.text(AppStrings.confirm));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        any(
          that: isA<ViolationFlagRequested>().having(
            (event) => event.attemptPublicId,
            'attempt id',
            'attempt-1',
          ),
        ),
      ),
    ).called(1);
  });
}
